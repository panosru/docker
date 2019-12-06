#++++++++++++++++++++++++++++++++++++++
# PHP application Docker container
#++++++++++++++++++++++++++++++++++++++

FROM php:7.4.0-fpm

ARG DEBIAN_FRONTEND=noninteractive

# Install required libraries and apps
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
    supervisor \
    logrotate \
    librabbitmq-dev \
    libc-client-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libkrb5-dev \
    libpq-dev \
    libmagickwand-dev \
    libyaml-dev \
    libmcrypt-dev \
    libpng-dev \
    libmemcached-dev \
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
    # wddx \
    pgsql \
    pdo_mysql \
    pdo_pgsql \
    zip \
    sysvmsg \
    sysvsem \
    sysvshm \
    tidy \
    xmlrpc \
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

# Install PECL php extensions
RUN yes '' | pecl install imagick && docker-php-ext-enable imagick \
    && pecl install msgpack && docker-php-ext-enable msgpack \
    && pecl install igbinary && docker-php-ext-enable igbinary \
    && pecl install mongodb && docker-php-ext-enable mongodb \
    && pecl install ast && docker-php-ext-enable ast \
    && pecl install psr && docker-php-ext-enable psr \
    && pecl install trader && docker-php-ext-enable trader \
    && yes '' | pecl install mcrypt && docker-php-ext-enable mcrypt \
    && yes '' | pecl install amqp && docker-php-ext-enable amqp \
    && yes '' | pecl install yaml && docker-php-ext-enable yaml \
    && yes 'yes' | pecl install redis && docker-php-ext-enable redis

# Install APCu and APC backward compatibility
RUN yes '' | pecl install apcu \
    && pecl install apcu_bc \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

# Install memcached from source
RUN git clone https://github.com/php-memcached-dev/php-memcached.git && \
    cd php-memcached && \
    phpize && \
    ./configure --enable-memcached --enable-memcached-session --enable-memcached-igbinary --enable-memcached-json --enable-memcached-msgpack --enable-memcached-sasl && \
    make && make install && \
    cd .. && \
    rm -rf php-memcached && \
    docker-php-ext-enable memcached

# Install Phalcon
ENV PHALCON_VERSION=4.0.0-rc.3

RUN curl -sSL "https://codeload.github.com/phalcon/cphalcon/tar.gz/v${PHALCON_VERSION}" | tar -xz \
    && cd cphalcon-${PHALCON_VERSION}/build \
    && ./install \
    && wget -P $(php-config --configure-options | grep -o "with-config-file-scan-dir=\([^ ]*\)" | awk -F'=' '{print $2}') "https://raw.githubusercontent.com/phalcon/cphalcon/3.4.x/tests/_ci/phalcon.ini" \
    && cd ../.. \
    && rm -rf cphalcon-${PHALCON_VERSION}

# Install Swoole
RUN git clone https://github.com/swoole/swoole-src.git && \
    cd swoole-src && \
    phpize && \
    ./configure --enable-openssl --enable-sockets --enable-http2 --enable-mysqlnd && \
    make && make install && \
    cd .. && \
    rm -rf swoole-src && git clone https://github.com/swoole/ext-async.git && \
    cd ext-async && \
    phpize && \
    ./configure --enable-swoole_async && \
    make && make install && \
    cd .. && \
    rm -rf ext-async && \
    docker-php-ext-enable swoole && docker-php-ext-enable swoole_async

# Install Composer
RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer \
    # parallel install plugin
    && composer global require hirak/prestissimo

ENV PATH $PATH:/root/composer/vendor/bin

# Clean up
RUN pecl clear-cache \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -Rf /tmp/*
