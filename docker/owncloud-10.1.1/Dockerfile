FROM owncloud/server:10.1.1 AS owncloud_legacy

FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive
ENV OWNCLOUD_VOLUME_CONFIG=/mnt/data/config
ENV OWNCLOUD_VOLUME_FILES=/mnt/data/files
ENV OWNCLOUD_VOLUME_APPS=/mnt/data/apps
ENV OWNCLOUD_DB_PREFIX=oc_

RUN printf '%s\n' \
        'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye main' \
        'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/20260824T000000Z bullseye-security main' \
        'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye-updates main' \
        > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        apache2 \
        bzip2 \
        ca-certificates \
        rsync \
        curl \
        gnupg \
        mariadb-client \
        php7.4-fpm \
        php7.4-bz2 \
        php7.4-cli \
        php7.4-curl \
        php7.4-gd \
        php7.4-intl \
        php7.4-mbstring \
        php7.4-mysql \
        php7.4-xml \
        php7.4-zip \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl --fail --silent --show-error --location https://packages.sury.org/php/apt.gpg \
        | gpg --dearmor --yes -o /etc/apt/keyrings/sury-php.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ bullseye main" \
        > /etc/apt/sources.list.d/sury-php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php7.2-fpm \
        php7.2-apcu \
        php7.2-bz2 \
        php7.2-cli \
        php7.2-curl \
        php7.2-gd \
        php7.2-intl \
        php7.2-mbstring \
        php7.2-mysql \
        php7.2-redis \
        php7.2-xml \
        php7.2-zip \
        php8.3-fpm \
        php7.4-redis \
        php7.4-apcu \
        php8.3-apcu \
        php8.3-bz2 \
        php8.3-cli \
        php8.3-curl \
        php8.3-gd \
        php8.3-intl \
        php8.3-mbstring \
        php8.3-mysql \
        php8.3-redis \
        php8.3-xml \
        php8.3-zip \
    && update-alternatives --set php /usr/bin/php7.4 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=owncloud_legacy /var/www/owncloud /var/www/owncloud
COPY docker/owncloud-10.1.1/apache-owncloud.conf /etc/apache2/sites-available/owncloud.conf
COPY docker/owncloud-10.1.1/entrypoint.sh /usr/local/bin/owncloud-test-entrypoint

RUN a2enmod proxy_fcgi setenvif rewrite headers \
    && a2dissite 000-default \
    && a2ensite owncloud \
    && chmod 0755 /usr/local/bin/owncloud-test-entrypoint \
    && chown -R www-data:root /var/www/owncloud \
    && usermod -aG sudo www-data

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/owncloud-test-entrypoint"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
