FROM php:8.4-fpm-alpine as php

RUN apk add --no-cache unzip libpq-dev gnutls-dev autoconf build-base \
    curl-dev nginx supervisor shadow bash sqlite sqlite-dev linux-headers \
    openssl ca-certificates
RUN docker-php-ext-install pdo pdo_sqlite
RUN pecl install xdebug && docker-php-ext-enable xdebug

WORKDIR /app

RUN addgroup --system --gid 1000 customgroup
RUN adduser --system --uid 1000 --ingroup customgroup customuser

# Setup PHP-FPM.
COPY docker/php/php.ini $PHP_INI_DIR/
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/php/conf.d/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

# Generate SSL certificate for custom domain
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=2pos.test" && \
    chown -R customuser:customgroup /etc/nginx && \
    chown -R customuser:customgroup /var/lib/nginx && \
    chown -R customuser:customgroup /var/log/nginx && \
    chmod 600 /etc/nginx/ssl/nginx.key && \
    chmod 644 /etc/nginx/ssl/nginx.crt

# Add Xdebug configuration
# Add Xdebug configuration with hostname
RUN echo "xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.discover_client_host=true" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Setup nginx.
COPY docker/nginx/nginx.conf docker/nginx/fastcgi_params docker/nginx/fastcgi_fpm docker/nginx/gzip_params /etc/nginx/
RUN mkdir -p /var/lib/nginx/tmp /var/log/nginx
RUN /usr/sbin/nginx -t -c /etc/nginx/nginx.conf

# Setup nginx user permissions.
RUN chown -R customuser:customgroup /usr/local/etc/php-fpm.d
RUN chown -R customuser:customgroup /var/lib/nginx
RUN chown -R customuser:customgroup /var/log/nginx

# Setup composer.
COPY --from=composer:2.8.5 /usr/bin/composer /usr/bin/composer

# Setup supervisor.
COPY docker/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Copy application sources into the container.
COPY --chown=customuser:customgroup . .
RUN chmod +x docker/entrypoint.sh
RUN chown -R customuser:customgroup /app
RUN chmod +w /app/public
RUN chown -R customuser:customgroup /var /run

USER customuser

# (Optional) Copy composer again if needed.
COPY --from=composer:2.8.5 /usr/bin/composer /usr/bin/composer

ENTRYPOINT ["docker/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
