#!/bin/bash
#
# ownCloud Classic Upgrade
#
# From: 10.1.1
# To:   11.1.0
# OS:   Debian 11
# Execution: root
#
# Usage:
#   ./oc-upgrade-stage.sh --oc-root /var/www/owncloud --oc-user www-data \
#     --oc-group www-data --php-bin /usr/bin/php7.2 \
#     --php-bin-7.4 /usr/bin/php7.4 \
#     --php-bin-8.3 /usr/bin/php8.3 --dry-run
#

set -Eeuo pipefail

# ============================================================
# Configuration
# ============================================================

OC_ROOT=""
OC_USER=""
OC_GROUP=""
PHP_BIN="/usr/bin/php7.2"
PHP_BIN_7_4="/usr/bin/php7.4"
PHP_BIN_8_3="/usr/bin/php8.3"
PHP_FPM_SOCKET="${OWNCLOUD_PHP_FPM_SOCKET:-/run/php/php-fpm.sock}"
WEB_PHP_HANDLER=""

WORK_DIR=""
RUN_DIR=""
ARCHIVE_DIR=""
EXTRACT_DIR=""

CURRENT_VERSION="10.1.1"
TARGET_VERSION="11.1.0"

PROTECTED_DIRS=(
    "error"
    "stats"
    "data"
    "config"
)

UPGRADE_VERSIONS=(
    "10.3.2"
    "10.5.0"
    "10.16.7"
    "11.0.1"
    "11.1.0"
)

declare -A DOWNLOAD_URLS=(
    ["10.3.2"]="https://github.com/owncloud/core/releases/download/v10.3.2/owncloud-10.3.2.tar.bz2"
    ["10.5.0"]="https://download.owncloud.com/server/stable/owncloud-10.5.0.tar.bz2"
    ["10.16.7"]="https://github.com/owncloud/core/releases/download/v10.16.7/owncloud-10.16.7.tar.bz2"
    ["11.0.1"]="https://github.com/owncloud/core/releases/download/v11.0.1/owncloud-11.0.1.tar.bz2"
    ["11.1.0"]="https://github.com/owncloud/core/releases/download/v11.1.0/owncloud-11.1.0.tar.bz2"
)

# SHA256 checksums published alongside the release archives.
declare -A SHA256=(
    ["10.3.2"]="0af4429bd477b4d9f829c9a69b47bb855d22c4a36de7d3e402f3852c33223c33"
    ["10.5.0"]="35232c0564cdb2140134563f339c6404bfb3d6133c54152cfaf207ce31aa1df1"
    ["10.16.7"]="0f0de5287641a8c8819de6d50f1d6b1c250cf5fa889f5027277cd782aad6375c"
    ["11.0.1"]="9aab53f5e28466e5c11b50206491fbc99ced31abb80885b026612fb611ee64d5"
    ["11.1.0"]="77e8d40253ad24892fde1ed38bb6aba05a2f5459cf68f29eee38f6090a8cadc6"
)

# ============================================================
# Runtime options
# ============================================================

DRY_RUN=false
OC_DATA_DIR=""
DISABLE_APPS=(activity bookmarks files_mediaviewer files_pdfviewer files_texteditor files_videoplayer gallery passman rainloop sensorlogger tasks calendar contacts files_videoplayer)
DISABLE_APPS_OPTION_SET=false

# ============================================================
# Logging
# ============================================================

log() {
    printf '[%s] INFO: %s\n' "$(date '+%F %T')" "$*"
}

warn() {
    printf '[%s] WARN: %s\n' "$(date '+%F %T')" "$*" >&2
}

die() {
    printf '[%s] ERROR: %s\n' "$(date '+%F %T')" "$*" >&2
    exit 1
}

# ============================================================
# Command execution
# ============================================================

run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf '[DRY-RUN] '
        printf '%q ' "$@"
        printf '\n'
    else
        "$@"
    fi
}

run_as_webuser() {
    run runuser -u "$OC_USER" -- "$@"
}

# ============================================================
# Argument parsing
# ============================================================

usage() {
    cat <<EOF
Usage: $0 --oc-root PATH --oc-user USER --oc-group GROUP [OPTIONS]

Options:
  --oc-root PATH        ownCloud installation directory (required)
  --oc-user USER        ownCloud web-server user (required)
  --oc-group GROUP      ownCloud web-server group (required)
  --php-bin PATH        PHP executable used through ownCloud 10.5.0
                        (default: /usr/bin/php7.2)
  --php-bin-7.4 PATH    PHP 7.4 executable used from ownCloud 10.16.7
                        (default: /usr/bin/php7.4)
  --php-bin-8.3 PATH    PHP 8.3 executable used from ownCloud 11.0.1
                        (default: /usr/bin/php8.3)
  --php-fpm-socket PATH Shared Apache-to-FPM socket (default:
                        /run/php/php-fpm.sock)
  --work-dir PATH       Upgrade working directory (default: current directory)
  --data-dir PATH       Absolute path to the ownCloud data directory
  --disable-apps LIST   Comma-separated apps to disable before upgrading;
                        first use replaces defaults, repeat to append
                        (default: passman,rainloop,sensorlogger,tasks)
  --dry-run             Simulate the upgrade without modifications
  --help                Show this help

Requirements:
  Run as root; PHP CLI 7.4 and 8.3, curl, tar, bzip2, rsync, sha256sum,
  runuser, and core system utilities must be available. If Apache module tools
are present, a2dismod, a2enmod, and apache2ctl must all be available. FPM
mode expects a shared socket symlink and php7.2-fpm.sock, php7.4-fpm.sock,
and php8.3-fpm.sock in the same directory.

EOF
}

require_option_value() {
    [[ $# -ge 2 && -n "$2" && "$2" != --* ]] ||
        die "Missing argument for $1"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --oc-root)
                require_option_value "$@"
                OC_ROOT="$2"
                shift 2
                ;;
            --oc-user)
                require_option_value "$@"
                OC_USER="$2"
                shift 2
                ;;
            --oc-group)
                require_option_value "$@"
                OC_GROUP="$2"
                shift 2
                ;;
            --php-bin)
                require_option_value "$@"
                PHP_BIN="$2"
                shift 2
                ;;
            --php-bin-7.4)
                require_option_value "$@"
                PHP_BIN_7_4="$2"
                shift 2
                ;;
            --php-bin-8.3)
                require_option_value "$@"
                PHP_BIN_8_3="$2"
                shift 2
                ;;
            --php-fpm-socket)
                require_option_value "$@"
                PHP_FPM_SOCKET="$2"
                shift 2
                ;;
            --work-dir)
                require_option_value "$@"
                WORK_DIR="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --data-dir)
                require_option_value "$@"
                [[ "$2" == /* ]] || die "--data-dir must be an absolute path."
                OC_DATA_DIR="$2"
                shift 2
                ;;
            --disable-apps)
                require_option_value "$@"
                if [[ "$DISABLE_APPS_OPTION_SET" == false ]]; then
                    DISABLE_APPS=()
                    DISABLE_APPS_OPTION_SET=true
                fi
                [[ "$2" != ,* && "$2" != *, && "$2" != *,,* ]] ||
                    die "--disable-apps must be a comma-separated list without empty entries."

                local app
                local -a requested_apps
                IFS=',' read -r -a requested_apps <<< "$2"
                for app in "${requested_apps[@]}"; do
                    [[ "$app" =~ ^[A-Za-z0-9_-]+$ ]] ||
                        die "Invalid app identifier in --disable-apps: $app"
                    if [[ ! " ${DISABLE_APPS[*]} " =~ " ${app} " ]]; then
                        DISABLE_APPS+=("$app")
                    fi
                done
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done

    [[ -n "$OC_ROOT" ]] || die "Required option --oc-root is missing."
    [[ -n "$OC_USER" ]] || die "Required option --oc-user is missing."
    [[ -n "$OC_GROUP" ]] || die "Required option --oc-group is missing."
    OC_ROOT="$(realpath -m -- "$OC_ROOT")"
    WORK_DIR="${WORK_DIR:-$PWD}"
    WORK_DIR="$(realpath -m -- "$WORK_DIR")"

    if [[ -z "$OC_DATA_DIR" ]]; then
        OC_DATA_DIR="${OC_ROOT}/data"
    fi
    OC_DATA_DIR="$(realpath -m -- "$OC_DATA_DIR")"

    ARCHIVE_DIR=""
    EXTRACT_DIR=""
}

# ============================================================
# Environment checks
# ============================================================

require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Required command not found: $1"
}

check_environment() {
    [[ $EUID -eq 0 ]] || die "Script must run as root."

    [[ -x "$PHP_BIN" ]] || die "PHP binary not found: $PHP_BIN"
    [[ -x "$PHP_BIN_7_4" ]] || die "PHP 7.4 binary not found: $PHP_BIN_7_4"
    [[ -x "$PHP_BIN_8_3" ]] || die "PHP 8.3 binary not found: $PHP_BIN_8_3"
    "$PHP_BIN" -r 'exit(0);' ||
        die "PHP binary cannot execute PHP code: $PHP_BIN"
    "$PHP_BIN_7_4" -r '
        exit(PHP_MAJOR_VERSION === 7 && PHP_MINOR_VERSION === 4 ? 0 : 1);
    ' || die "Expected PHP 7.4 at: $PHP_BIN_7_4"
    "$PHP_BIN_8_3" -r '
        exit(PHP_MAJOR_VERSION === 8 && PHP_MINOR_VERSION === 3 ? 0 : 1);
    ' || die "Expected PHP 8.3 at: $PHP_BIN_8_3"

    local required_commands=(
        curl tar bzip2 rsync sha256sum runuser realpath id getent date mkdir mktemp rm
        ln mv readlink stat dirname
    )
    local command_name

    for command_name in "${required_commands[@]}"; do
        require_command "$command_name"
    done

    local apache_tools=(a2dismod a2enmod apache2ctl)
    local apache_tools_found=0

    for command_name in "${apache_tools[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            apache_tools_found=$((apache_tools_found + 1))
        fi
    done

    if (( apache_tools_found > 0 && apache_tools_found < ${#apache_tools[@]} )); then
        die "Apache PHP switching requires a2dismod, a2enmod, and apache2ctl."
    fi

    [[ -d "$OC_ROOT" ]] || die "Installation directory not found."

    [[ -f "$OC_ROOT/occ" ]] || die "OCC not found."
    [[ -f "$OC_ROOT/config/config.php" ]] || die "Configuration not found."

    id "$OC_USER" >/dev/null 2>&1 || die "Web user does not exist."
    getent group "$OC_GROUP" >/dev/null || die "Web group does not exist."

    detect_web_php_handler
    check_config_permissions

    log "Environment checks passed."
}

detect_web_php_handler() {
    local apache_modules=""
    local module_path
    local has_mod_php=false

    if command -v apache2ctl >/dev/null 2>&1; then
        apache_modules="$(apache2ctl -M 2>/dev/null || true)"
    fi

    if [[ "$apache_modules" == *proxy_fcgi_module* || -S "$PHP_FPM_SOCKET" ]]; then
        WEB_PHP_HANDLER="fpm"
        [[ -L "$PHP_FPM_SOCKET" ]] ||
            die "PHP-FPM shared socket must be a symlink: $PHP_FPM_SOCKET"
        [[ -S "$PHP_FPM_SOCKET" ]] ||
            die "PHP-FPM handler detected, but socket is missing: $PHP_FPM_SOCKET"

        local fpm_version
        local fpm_socket
        local fpm_socket_dir
        fpm_socket_dir="$(dirname -- "$PHP_FPM_SOCKET")"
        for fpm_version in 7.2 7.4 8.3; do
            fpm_socket="${fpm_socket_dir}/php${fpm_version}-fpm.sock"
            [[ -S "$fpm_socket" ]] ||
                die "PHP-FPM socket for PHP $fpm_version is missing: $fpm_socket"
        done

        log "Detected PHP-FPM handler via $PHP_FPM_SOCKET"
        return
    fi

    for module_path in /etc/apache2/mods-enabled/php*.load; do
        if [[ -e "$module_path" ]]; then
            has_mod_php=true
            break
        fi
    done

    if [[ "$has_mod_php" == true ]]; then
        WEB_PHP_HANDLER="apache-module"
        log "Detected Apache mod_php handler."
        return
    fi

    die "Could not detect a PHP-FPM socket or enabled Apache PHP module."
}

check_config_permissions() {
    local config_dir="${OC_ROOT}/config"
    local config_file="${config_dir}/config.php"
    local config_target
    local config_file_target

    [[ -d "$config_dir" ]] || die "Configuration directory not found: $config_dir"
    config_target="$(realpath -e -- "$config_dir")" ||
        die "Could not resolve configuration directory: $config_dir"
    config_file_target="$(realpath -e -- "$config_file")" ||
        die "Could not resolve configuration file: $config_file"

    if [[ -L "$config_dir" ]]; then
        log "Configuration directory is a symlink: $config_dir -> $config_target"
    else
        log "Configuration directory is not a symlink: $config_dir"
    fi

    log "Configuration target permissions: $(stat -c '%A (%a) %U:%G' -- "$config_target")"
    log "Configuration file permissions: $(stat -c '%A (%a) %U:%G' -- "$config_file_target")"

    runuser -u "$OC_USER" -- test -w "$config_target" ||
        die "Configuration directory is not writable by $OC_USER: $config_target"

    runuser -u "$OC_USER" -- test -w "$config_file_target" ||
        die "Configuration file is not writable by $OC_USER: $config_file_target"
}

# ============================================================
# Read configured data directory
# ============================================================

get_configured_data_dir() {
    "$PHP_BIN" -r '
        $CONFIG = [];
        include $argv[1];
        echo $CONFIG["datadirectory"] ?? "";
    ' "$OC_ROOT/config/config.php"
}

check_data_directory() {
    local configured_dir

    configured_dir="$(get_configured_data_dir)"

    [[ -n "$configured_dir" ]] ||
        die "Could not determine configured data directory."

    OC_DATA_DIR="$(realpath -m "$OC_DATA_DIR")"
    configured_dir="$(realpath -m "$configured_dir")"

    [[ "$OC_DATA_DIR" == "$configured_dir" ]] ||
        die "--data-dir does not match the configured data directory."

    [[ -d "$OC_DATA_DIR" ]] ||
        die "Data directory does not exist: $OC_DATA_DIR"

    log "Data directory: $OC_DATA_DIR"
}

# ============================================================
# Installed version
# ============================================================

get_installed_version() {
    "$PHP_BIN_7_4" -r '
        $CONFIG = [];
        include $argv[1];
        $version = $CONFIG["version"] ?? "";
        if (!is_string($version) || $version === "") {
            exit(1);
        }
        echo $version;
    ' "$OC_ROOT/config/config.php"
}

get_source_version() {
    "$PHP_BIN_7_4" -r '
        $OC_VersionString = "";
        include $argv[1];
        if (!is_string($OC_VersionString) || $OC_VersionString === "") {
            exit(1);
        }
        echo $OC_VersionString;
    ' "$OC_ROOT/version.php"
}

version_matches() {
    local actual="$1"
    local expected="$2"

    [[ "$actual" == "$expected" || "$actual" == "$expected".* ]]
}

verify_installed_version() {
    local expected="$1"
    local actual

    actual="$(get_installed_version)"
    [[ -n "$actual" ]] || die "Could not determine installed version."

    if ! version_matches "$actual" "$expected"; then
        die "Version mismatch. Expected $expected, got $actual"
    fi

    log "Verified installed version: $actual"
}

# ============================================================
# Download verification
# ============================================================

verify_download_source() {
    local version="$1"
    local expected_url="${DOWNLOAD_URLS[$version]:-}"
    local supplied_url="$2"

    [[ -n "$expected_url" ]] || die "Unknown release: $version"

    [[ "$supplied_url" == "$expected_url" ]] ||
        die "Unexpected download source for $version."
}

download_source() {
    local version="$1"
    local url="${DOWNLOAD_URLS[$version]}"
    local archive="${ARCHIVE_DIR}/owncloud-${version}.tar.bz2"

    verify_download_source "$version" "$url"

    [[ -n "${SHA256[$version]:-}" ]] ||
        die "Missing pinned SHA256 checksum for $version."
    [[ "${SHA256[$version]}" =~ ^[[:xdigit:]]{64}$ ]] ||
        die "Invalid pinned SHA256 checksum for $version."

    log "Downloading ownCloud $version"

    run mkdir -p "$ARCHIVE_DIR"

    run curl \
        --fail \
        --location \
        --retry 3 \
        --output "$archive" \
        "$url"

    if [[ "$DRY_RUN" == false ]]; then
        printf '%s  %s\n' "${SHA256[$version]}" "$archive" |
            sha256sum --check --status ||
            die "SHA256 verification failed for $version."
    fi

    log "Archive verified: $version"
}

# ============================================================
# Extraction
# ============================================================

extract_source() {
    local version="$1"
    local archive="${ARCHIVE_DIR}/owncloud-${version}.tar.bz2"
    local destination="${EXTRACT_DIR}/${version}"

    log "Extracting ownCloud $version"

    run mkdir -p "$destination"

    run tar -xjf "$archive" -C "$destination"

    if [[ "$DRY_RUN" == false ]]; then
        [[ -f "$destination/owncloud/occ" ]] ||
            die "Invalid archive structure for $version."
    fi
}

# ============================================================
# Source replacement
# ============================================================

replace_source() {
    local version="$1"
    local source="${EXTRACT_DIR}/${version}/owncloud"

    log "Replacing ownCloud source with $version"

    local rsync_args=(
        --archive
        --delete
        "--chown=${OC_USER}:${OC_GROUP}"
        --chmod=D750,F640
    )

    local protected

    for protected in "${PROTECTED_DIRS[@]}"; do
        rsync_args+=("--exclude=/${protected}")
    done

    # Protect a custom data directory if it is inside OC_ROOT.
    if [[ "$OC_DATA_DIR" == "$OC_ROOT/"* ]]; then
        local relative_data_dir="${OC_DATA_DIR#"$OC_ROOT"/}"
        rsync_args+=("--exclude=/${relative_data_dir}")
    fi

    # Keep rsync --delete from removing the extracted source when WORK_DIR is
    # inside OC_ROOT.
    if [[ "$RUN_DIR" == "$OC_ROOT/"* ]]; then
        local relative_run_dir="${RUN_DIR#"$OC_ROOT"/}"
        rsync_args+=("--exclude=/${relative_run_dir}")
    fi

    run rsync "${rsync_args[@]}" "${source}/" "${OC_ROOT}/"
    if [[ "$DRY_RUN" == false ]]; then
        check_config_permissions
    fi

    log "Source replacement completed."
}

# ============================================================
# Maintenance mode
# ============================================================

enable_maintenance_mode() {
    log "Enabling maintenance mode"

    run_as_webuser "$PHP_BIN" "$OC_ROOT/occ" maintenance:mode --on
}

disable_apps_before_upgrade() {
    local app

    for app in "${DISABLE_APPS[@]}"; do
        log "Disabling app: $app"
        if run_as_webuser "$PHP_BIN" "$OC_ROOT/occ" app:disable "$app"; then
            log "App disabled: $app"
        else
            warn "Could not disable app '$app'; it may not be installed. Continuing."
        fi
    done
}

disable_maintenance_mode() {
    log "Disabling maintenance mode"

    run_as_webuser "$PHP_BIN" "$OC_ROOT/occ" maintenance:mode --off
}

# ============================================================
# Execute upgrade
# ============================================================

execute_upgrade() {
    local version="$1"

    log "Executing OCC upgrade to $version"

    run_as_webuser "$PHP_BIN" "$OC_ROOT/occ" upgrade

    verify_installed_version "$version"
}

switch_apache_php_module() {
    local target_module="$1"

    if command -v a2dismod >/dev/null && command -v a2enmod >/dev/null; then
        local enabled_module
        local module_name
        local target_enabled=false
        local changed=false

        for enabled_module in /etc/apache2/mods-enabled/php*.load; do
            [[ -e "$enabled_module" ]] || continue
            module_name="${enabled_module##*/}"
            module_name="${module_name%.load}"

            if [[ "$module_name" == "$target_module" ]]; then
                target_enabled=true
            else
                log "Disabling Apache PHP module: $module_name"
                run a2dismod "$module_name"
                changed=true
            fi
        done

        if [[ "$target_enabled" == false ]]; then
            log "Enabling Apache PHP module: $target_module"
            run a2enmod "$target_module"
            changed=true
        fi

        if [[ "$changed" == true ]]; then
            run apache2ctl -k graceful
        fi
    elif command -v apache2ctl >/dev/null; then
        die "Apache PHP switching requires a2dismod and a2enmod."
    fi
}

switch_php_fpm_socket() {
    local php_version="$1"
    local socket_directory
    local target_socket
    local temporary_socket

    socket_directory="$(dirname -- "$PHP_FPM_SOCKET")"
    target_socket="${socket_directory}/php${php_version}-fpm.sock"
    [[ -S "$target_socket" ]] ||
        die "PHP-FPM socket for PHP $php_version is missing: $target_socket"

    temporary_socket="${PHP_FPM_SOCKET}.upgrade.$$"
    log "Switching PHP-FPM backend to PHP $php_version: $target_socket"
    run ln -sfn -- "$target_socket" "$temporary_socket"
    run mv -Tf -- "$temporary_socket" "$PHP_FPM_SOCKET"
}

switch_to_php_7_4() {
    PHP_BIN="$PHP_BIN_7_4"
    if [[ "$WEB_PHP_HANDLER" == "fpm" ]]; then
        switch_php_fpm_socket 7.4
    fi
    log "Switched PHP CLI runtime to PHP 7.4: $PHP_BIN"
}

switch_to_php_8_3() {
    PHP_BIN="$PHP_BIN_8_3"
    if [[ "$WEB_PHP_HANDLER" == "fpm" ]]; then
        switch_php_fpm_socket 8.3
    fi
    log "Switched PHP CLI runtime to PHP 8.3: $PHP_BIN"
}

switch_web_handler_to_php_8_3() {
    if [[ "$WEB_PHP_HANDLER" == "fpm" ]]; then
        switch_php_fpm_socket 8.3
    else
        switch_apache_php_module php8.3
    fi
}

# ============================================================
# Permissions
# ============================================================

set_permissions() {
    log "Checking source ownership and permissions."

    # Source files are already assigned ownership and permissions
    # through rsync --chown and --chmod.
    #
    # Protected directories are deliberately excluded.
}

# ============================================================
# Upgrade milestone
# ============================================================

upgrade_milestone() {
    local version="$1"

    log "============================================"
    log "Starting milestone: $version"
    log "============================================"

    download_source "$version"
    extract_source "$version"
    replace_source "$version"
    set_permissions

    if [[ "$version" == "10.16.7" ]]; then
        switch_to_php_7_4
    elif [[ "$version" == "11.0.1" ]]; then
        switch_to_php_8_3
    fi

    execute_upgrade "$version"

    log "Milestone $version completed successfully."
}

# ============================================================
# Dry-run
# ============================================================

show_dry_run() {
    log "DRY-RUN: No system changes will be performed."

    log "Installation: $OC_ROOT"
    log "Data directory: $OC_DATA_DIR"
    log "Working directory: $WORK_DIR"
    log "Current version: $CURRENT_VERSION"
    log "Target version: $TARGET_VERSION"
    log "PHP runtime transitions: configured PHP through 10.5.0, PHP 7.4 from 10.16.7, PHP 8.3 from 11.0.1"
    log "Web PHP handler: $WEB_PHP_HANDLER"

    log "Planned maintenance mode: ON"

    if ((${#DISABLE_APPS[@]} > 0)); then
        log "Apps to disable before upgrade: ${DISABLE_APPS[*]}"
    else
        log "No apps configured for disabling."
    fi

    for version in "${UPGRADE_VERSIONS[@]}"; do
        log "Would upgrade to: $version"
    done

    log "Planned maintenance mode: OFF"

    log "Dry-run completed."
}

# ============================================================
# Cleanup
# ============================================================

cleanup() {
    local exit_code=$?

    if [[ -n "$RUN_DIR" && $exit_code -eq 0 && "$DRY_RUN" == false ]]; then
        log "Removing temporary upgrade files: $RUN_DIR"
        rm -rf -- "$RUN_DIR"
    elif [[ $exit_code -ne 0 ]]; then
        if [[ -n "$RUN_DIR" ]]; then
            warn "Upgrade failed. Temporary files retained: $RUN_DIR"
        fi
        warn "Maintenance mode has NOT been automatically disabled."
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    parse_arguments "$@"

    check_environment
    check_data_directory

    if [[ "$DRY_RUN" == true ]]; then
        show_dry_run
        return 0
    fi

    local installed_version
    installed_version="$(get_installed_version)"

    local source_version
    source_version="$(get_source_version)"

    case "$source_version" in
        10.16.7*)
            switch_to_php_7_4
            ;;
        11.0.1*|11.1.0*)
            switch_to_php_8_3
            ;;
    esac

    log "Detected installed version: $installed_version"

    local start_index=0

    if ! version_matches "$installed_version" "$CURRENT_VERSION"; then
        local found=false

        for i in "${!UPGRADE_VERSIONS[@]}"; do
            if version_matches "$installed_version" "${UPGRADE_VERSIONS[$i]}"; then
                start_index=$((i + 1))
                found=true
                break
            fi
        done

        [[ "$found" == true ]] ||
            die "Unexpected installed version: $installed_version"
    fi

    if (( start_index >= ${#UPGRADE_VERSIONS[@]} )); then
        switch_to_php_8_3
        switch_web_handler_to_php_8_3
        log "Target version already installed."
        return 0
    fi

    verify_installed_version "$installed_version"

    run mkdir -p "$WORK_DIR"
    RUN_DIR="$(mktemp -d -- "$WORK_DIR/.owncloud-upgrade.XXXXXX")"
    ARCHIVE_DIR="${RUN_DIR}/archives"
    EXTRACT_DIR="${RUN_DIR}/extracted"
    trap cleanup EXIT

    run mkdir -p "$ARCHIVE_DIR" "$EXTRACT_DIR"

    enable_maintenance_mode
    disable_apps_before_upgrade

    for ((i=start_index; i<${#UPGRADE_VERSIONS[@]}; i++)); do
        upgrade_milestone "${UPGRADE_VERSIONS[$i]}"
    done

    verify_installed_version "$TARGET_VERSION"

    disable_maintenance_mode

    # Mod_php reloads can interrupt OCC or the foreground Apache process.
    # FPM switches use an atomic socket link and do not reload Apache.
    if [[ "$WEB_PHP_HANDLER" == "apache-module" ]]; then
        switch_web_handler_to_php_8_3
    fi

    log "============================================"
    log "ownCloud upgrade completed successfully."
    log "Installed version: $TARGET_VERSION"
    log "============================================"
}

main "$@"