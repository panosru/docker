#++++++++++++++++++++++++++++++++++++++
# PHP application Docker container
#++++++++++++++++++++++++++++++++++++++

FROM php:8.2.16-fpm

ARG DEBIAN_FRONTEND=noninteractive

# Install the Docker PHP Extension Installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required libraries and apps
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends apt-utils \
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
    && rm -r /var/lib/apt/lists/*

# Install Php extensions
RUN docker-php-ext-install -j$(nproc) \
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
    && docker-php-ext-configure ldap \
        --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && set -eux; PHP_OPENSSL=yes docker-php-ext-configure imap \
        --with-kerberos \
        --with-imap-ssl \
    && docker-php-ext-install imap

# Use the Docker PHP Extension Installer to install PHP extensions
RUN install-php-extensions \
    imagick

# Install PECL php extensions
#RUN yes '' | pecl install imagick-3.7.0 && docker-php-ext-enable imagick
RUN pecl install msgpack && docker-php-ext-enable msgpack
RUN pecl install igbinary && docker-php-ext-enable igbinary
RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN pecl install ast && docker-php-ext-enable ast
RUN pecl install psr && docker-php-ext-enable psr
RUN pecl install trader && docker-php-ext-enable trader
RUN pecl install phalcon && docker-php-ext-enable phalcon
RUN pecl install zephir_parser && docker-php-ext-enable zephir_parser
RUN pecl install mailparse && docker-php-ext-enable mailparse
RUN yes '' | pecl install mcrypt && docker-php-ext-enable mcrypt
RUN yes '' | pecl install xmlrpc-1.0.0RC3 && docker-php-ext-enable xmlrpc
RUN yes '' | pecl install amqp && docker-php-ext-enable amqp
RUN yes '' | pecl install yaml && docker-php-ext-enable yaml
RUN yes 'yes' | pecl install redis && docker-php-ext-enable redis
RUN yes '' | pecl install apcu && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini

# Install memcached from source
RUN git clone https://github.com/php-memcached-dev/php-memcached.git && \
    cd php-memcached && \
    phpize && \
    ./configure --enable-memcached --enable-memcached-session --enable-memcached-igbinary --enable-memcached-json --enable-memcached-msgpack --enable-memcached-sasl && \
    make && make install && \
    cd .. && \
    rm -rf php-memcached && \
    docker-php-ext-enable memcached

RUN pecl install memcache && docker-php-ext-enable memcache --ini-name 10-docker-php-ext-memcache.ini

# Install Swoole
RUN git clone https://github.com/openswoole/swoole-src.git && \
    cd swoole-src && \
    phpize && \
    ./configure --enable-openssl --enable-http2 --enable-swoole --enable-mysqlnd --enable-swoole-json --enable-swoole-curl && \
    make && make install && \
    docker-php-ext-enable openswoole && \
    cd .. && \
    rm -rf swoole-src

# Install Wddx
COPY ./wddx ./wddx
RUN cd wddx && phpize && ./configure && make && make install && cd .. && rm -rf wddx

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
    && echo "zend_extension=$php_extension_dir/ioncube_loader_lin_$php_version.so" > $php_additional_ini/00-ioncube.ini

# Instal SourceGuardian loader
RUN php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && php_extension_dir=$(php -r "echo ini_get('extension_dir');") \
    && php_additional_ini=$(php -i | grep 'additional .ini files' | pcregrep -o1 '=> (.+)') \
    && cd /tmp \
    && curl -fSL 'https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz' -o sg.tar.gz \
    && mkdir -p sg \
    && tar -xf sg.tar.gz -C sg \
    && rm sg.tar.gz \
    && mv sg/ixed.$php_version.lin $php_extension_dir/sourceguardian_$php_version.so \
    && rm -r sg \
    && echo "extension=$php_extension_dir/sourceguardian_$php_version.so" > $php_additional_ini/15-sourceguardian.ini

# Install Composer
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer

ENV PATH $PATH:/root/composer/vendor/bin

# Clean up
RUN pecl clear-cache \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -Rf /tmp/*
