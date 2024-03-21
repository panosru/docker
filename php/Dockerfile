# Define ARG at the top to allow it to be available in all stages
ARG VERSION


##################
## Base Builder ##
##################

# This intermediate stage handles common setup tasks to avoid duplication
FROM php:${VERSION}-fpm as base-builder

# Set default environment variables used across stages
ENV APPLICATION_USER=application \
    APPLICATION_GROUP=application \
    APPLICATION_PATH=/app \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000

# Common setup: Install Composer, setup application user
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer \
    && groupadd -g "$APPLICATION_GID" "$APPLICATION_GROUP" \
    && useradd -u "$APPLICATION_UID" --home "/home/application" --create-home --shell /bin/bash --no-user-group "$APPLICATION_USER" \
    && usermod -g "$APPLICATION_GROUP" "$APPLICATION_USER" \
    && mkdir -p /var/www/html && chown -R "$APPLICATION_USER":"$APPLICATION_GROUP" /var/www/html


################
## Base Stage ##
################
FROM base-builder as base
ARG DEBIAN_FRONTEND=noninteractive

# Install the Docker PHP Extension Installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install system dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    # System dependencies
        apt-utils \
        pcregrep \
        supervisor \
        logrotate \
        librabbitmq-dev \
        libc-client-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libpq-dev \
        libcurl4-openssl-dev \
        libmagickwand-dev \
        libyaml-dev \
        libmcrypt-dev \
        libpng-dev \
        libmemcached-dev \
        libgmp-dev \
        libz-dev \
        libsasl2-dev \
        libldap2-dev \
        zlib1g-dev \
        libzip-dev \
        libpspell-dev \
        libnghttp2-dev \
        liblz4-dev \
        libzstd-dev \
        libtidy-dev \
        libxslt1-dev \
        libwebp-dev \
        libxpm-dev \
        memcached \
        wget \
        git \
        unzip \
        zip \
    # Install PHP extensions
    && docker-php-ext-install -j$(nproc) \
        bz2 \
        bcmath \
        calendar \
        curl \
        dba \
        exif \
        gettext \
        pcntl \
        soap \
        shmop \
        mysqli \
        sockets \
        opcache \
        pspell \
        gmp \
        pgsql \
        pdo_mysql \
        pdo_pgsql \
        zip \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        tidy \
        xsl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && set -eux; PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    # Use the Docker PHP Extension Installer to simplify installation of extensions not available through docker-php-ext-install
    && chmod +x /usr/local/bin/install-php-extensions && sync \
    && install-php-extensions \
        imagick \
        msgpack \
        igbinary \
        mongodb \
        ast \
        psr \
        trader \
        phalcon \
        zephir_parser \
        mailparse \
        mcrypt \
        xmlrpc \
        amqp \
        yaml \
        redis \
        apcu \
    # Install memcached from source
    && git clone https://github.com/php-memcached-dev/php-memcached.git \
    && cd php-memcached \
    && phpize \
    && ./configure --enable-memcached --enable-memcached-session --enable-memcached-igbinary --enable-memcached-json --enable-memcached-msgpack --enable-memcached-sasl \
    && make && make install \
    && cd .. && rm -rf php-memcached \
    && docker-php-ext-enable memcached \
    && pecl install memcache && docker-php-ext-enable memcache --ini-name 10-docker-php-ext-memcache.ini

# Copy wddx source for later installation 
COPY ./wddx /usr/src/php/ext/wddx

    # Install Swoole
RUN git clone https://github.com/openswoole/swoole-src.git \
    && cd swoole-src \
    && phpize \
    && ./configure --enable-openssl --enable-http2 --enable-swoole --enable-mysqlnd --enable-swoole-json --enable-swoole-curl \
    && make && make install \
    && docker-php-ext-enable openswoole \
    && cd .. && rm -rf swoole-src \
    # Install Wddx
    && docker-php-ext-install wddx \
    # Cleanup
    && apt-get clean \
    && rm -rf /usr/src/php/ext/wddx \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && (mkdir -p /tmp/pear/cache || true) && pecl clear-cache && composer clear-cache
    

# Copy the common setup from base-builder
COPY --from=base-builder /usr/local/bin/composer /usr/local/bin/composer
COPY --from=base-builder /root/composer /root/composer
COPY --from=base-builder /etc/passwd /etc/passwd
COPY --from=base-builder /etc/group /etc/group
COPY --from=base-builder /home /home
COPY --from=base-builder /var/www/html /var/www/html


#######################
## Base With Loaders ##
#######################
FROM base as base-with-loaders

# Install ioncube loader, SourceGuardian loader, etc.

    # Install ioncube loader
RUN php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && php_extension_dir=$(php -r "echo ini_get('extension_dir');") \
    && php_additional_ini=$(php -i | grep 'additional .ini files' | pcregrep -o1 '=> (.+)') \
    && cd /tmp \
    && curl -fSL 'http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz' -o ioncube.tar.gz \
    && mkdir -p ioncube \
    && tar -xf ioncube.tar.gz -C ioncube --strip-components=1 \
    && rm ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_$php_version.so $php_extension_dir/ioncube_loader_lin_$php_version.so \
    && rm -r ioncube \
    && echo "zend_extension=$php_extension_dir/ioncube_loader_lin_$php_version.so" > $php_additional_ini/00-ioncube.ini \
    # Instal SourceGuardian loader
    && php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && php_extension_dir=$(php -r "echo ini_get('extension_dir');") \
    && php_additional_ini=$(php -i | grep 'additional .ini files' | pcregrep -o1 '=> (.+)') \
    && cd /tmp \
    && curl -fSL 'https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz' -o sg.tar.gz \
    && mkdir -p sg \
    && tar -xf sg.tar.gz -C sg \
    && rm sg.tar.gz \
    && mv sg/ixed.$php_version.lin $php_extension_dir/sourceguardian_$php_version.so \
    && rm -r sg \
    && echo "extension=$php_extension_dir/sourceguardian_$php_version.so" > $php_additional_ini/15-sourceguardian.ini \
    # Clean up
    && rm -Rf /tmp/*


#######################
## Development Stage ##
#######################
FROM base as development

    # Install Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug \
    # Install Blackfire
    && version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    # Clean up
    && pecl clear-cache \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /tmp/*

# Set the environment context to development
ENV PROVISION_CONTEXT "development"

# Set the working directory to /var/www/html
WORKDIR /var/www/html

USER "$APPLICATION_USER"


####################################
## Development Stage With Loaders ##
####################################
FROM base-with-loaders as development-with-loaders

# Reuse the development stage setup and add loader support
COPY --from=development /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Set the environment context to development with loaders
ENV PROVISION_CONTEXT "development"

# Set the working directory to /var/www/html
WORKDIR /var/www/html

USER "$APPLICATION_USER"


######################
## Production Stage ##
######################
FROM base as production

# Set the environment context to development
ENV PROVISION_CONTEXT "production"

# Set the working directory to /var/www/html
WORKDIR /var/www/html

USER "$APPLICATION_USER"


###################################
## Production Stage With Loaders ##
###################################
FROM base-with-loaders as production-with-loaders

# Reuse the production stage setup and add loader support
COPY --from=production /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Keep the environment context consistent for production stages
ENV PROVISION_CONTEXT "production"

# Set the working directory to /var/www/html
WORKDIR /var/www/html

USER "$APPLICATION_USER"
