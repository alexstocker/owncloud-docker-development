#!/bin/bash
set -Eeuo pipefail

mkdir -p "$OWNCLOUD_VOLUME_CONFIG" "$OWNCLOUD_VOLUME_FILES" "$OWNCLOUD_VOLUME_APPS"
chown -R www-data:root /mnt/data

for php_version in 7.2 7.4 8.3; do
    service "php${php_version}-fpm" start
done

php_version=7.2
source_version="$(php7.4 -r '
    $OC_VersionString = "";
    include "/var/www/owncloud/version.php";
    echo $OC_VersionString;
')"
case "$source_version" in
    10.16.7*)
        php_version=7.4
        ;;
    11.*)
        php_version=8.3
        ;;
esac
ln -sfn "/run/php/php${php_version}-fpm.sock" /run/php/php-fpm.sock

upgrade_script=/usr/local/bin/owncloud-upgrade.sh
if [[ ! -f "$upgrade_script" ]]; then
    printf 'Upgrade script is missing or not a regular file: %s\n' "$upgrade_script" >&2
    exit 1
fi
chmod a+x "$upgrade_script"

if [[ ! -L /var/www/owncloud/config ]]; then
    rm -rf /var/www/owncloud/config
    ln -s "$OWNCLOUD_VOLUME_CONFIG" /var/www/owncloud/config
fi

if [[ ! -L /var/www/owncloud/custom ]]; then
    rm -rf /var/www/owncloud/custom
    ln -s "$OWNCLOUD_VOLUME_APPS" /var/www/owncloud/custom
fi

if [[ ! -f "$OWNCLOUD_VOLUME_CONFIG/config.php" ]]; then
    : "${OWNCLOUD_DB_HOST:?OWNCLOUD_DB_HOST is required}"
    : "${OWNCLOUD_DB_NAME:?OWNCLOUD_DB_NAME is required}"
    : "${OWNCLOUD_DB_USERNAME:?OWNCLOUD_DB_USERNAME is required}"
    : "${OWNCLOUD_DB_PASSWORD:?OWNCLOUD_DB_PASSWORD is required}"
    : "${OWNCLOUD_ADMIN_USERNAME:?OWNCLOUD_ADMIN_USERNAME is required}"
    : "${OWNCLOUD_ADMIN_PASSWORD:?OWNCLOUD_ADMIN_PASSWORD is required}"

    for attempt in {1..60}; do
        if mariadb-admin ping --silent --host="$OWNCLOUD_DB_HOST" \
            --user="$OWNCLOUD_DB_USERNAME" --password="$OWNCLOUD_DB_PASSWORD"; then
            break
        fi

        if (( attempt == 60 )); then
            printf 'Database did not become available: %s\n' "$OWNCLOUD_DB_HOST" >&2
            exit 1
        fi
        sleep 2
    done

    runuser -u www-data -- php7.2 /var/www/owncloud/occ maintenance:install \
        --no-interaction \
        --data-dir "$OWNCLOUD_VOLUME_FILES" \
        --database mysql \
        --database-name "$OWNCLOUD_DB_NAME" \
        --database-user "$OWNCLOUD_DB_USERNAME" \
        --database-pass "$OWNCLOUD_DB_PASSWORD" \
        --database-host "$OWNCLOUD_DB_HOST" \
        --admin-user "$OWNCLOUD_ADMIN_USERNAME" \
        --admin-pass "$OWNCLOUD_ADMIN_PASSWORD"
fi

exec "$@"
