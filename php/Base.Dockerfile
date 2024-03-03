ARG VERSION

FROM php:$VERSION-fpm

ARG DEBIAN_FRONTEND=noninteractive

# Install required libraries and apps
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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

# Install the Docker PHP Extension Installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Use the Docker PHP Extension Installer to install PHP extensions
RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions \
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
    apcu

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

# Install Composer
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer

ENV PATH $PATH:/root/composer/vendor/bin

# Clean up
RUN pecl clear-cache \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -Rf /tmp/*
