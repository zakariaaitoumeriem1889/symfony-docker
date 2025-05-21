FROM php:8.3-fpm-alpine

# Install necessary packages
RUN apk update && apk add --no-cache \
    bash git zip unzip curl libzip-dev libpng-dev libxml2-dev icu-dev postgresql-dev \
    oniguruma-dev linux-headers bash-completion git-bash-completion shadow nano sudo \
    wget gnupg ca-certificates icu-dev imagemagick-dev libpng-dev libjpeg-turbo-dev \
    freetype-dev libpq-dev $PHPIZE_DEPS && rm -rf /var/cache/apk/*

# Configurer Bash completion
RUN mkdir -p /etc/bash_completion.d && \
    curl -o /etc/bash_completion.d/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

# Install PHP extensions installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install PHP extensions
RUN install-php-extensions opcache bcmath calendar intl pdo pdo_pgsql pgsql exif zip \
    gd imagick xdebug redis soap xsl pcntl sockets mbstring

# Create directory structure for app and set permissions
RUN mkdir -p /var/www/app/var/cache /var/www/app/var/log

# Configure PHP
COPY conf/php.ini /usr/local/etc/php/conf.d/php.ini
COPY conf/php-fpm.ini /usr/local/etc/php-fpm.d/zz-php-fpm.conf
COPY conf/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY conf/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Create xdebug log directory with proper permissions
RUN mkdir -p /var/log && \
    touch /var/log/xdebug.log && \
    chmod 664 /var/log/xdebug.log && \
    chown www-data:www-data /var/log/xdebug.log

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.alpine.sh' | bash \
    && apk add --no-cache symfony-cli

# Set working directory
WORKDIR /var/www/app

# Set up bash completion
RUN echo 'if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi' >> ~/.bashrc && \
    echo 'if [ -f /usr/share/bash-completion/completions/git ]; then . /usr/share/bash-completion/completions/git; fi' >> ~/.bashrc

# Copy and set up entrypoint script
COPY ./scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

COPY ./scripts/symfony-optimize.sh /usr/local/bin/symfony-optimize
RUN chmod +x /usr/local/bin/symfony-optimize

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]

# Fix permissions - use 1000:1000 for better host machine compatibility
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data && \
    chown -R www-data:www-data /var/www && \
    find /var/www -type d -exec chmod 755 {} \; && \
    find /var/www -type f -exec chmod 644 {} \; && \
    chmod -R 775 /var/www/app/var

RUN git config --global --add safe.directory /var/www/app