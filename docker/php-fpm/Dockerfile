FROM docker.io/library/php:8.5-fpm-alpine

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY docker/php-fpm/php.ini $PHP_INI_DIR/conf.d/zz-app.ini
COPY docker/php-fpm/zz-app.conf /usr/local/etc/php-fpm.d/zz-app.conf
COPY app/ /var/www/html/

USER 82:82
