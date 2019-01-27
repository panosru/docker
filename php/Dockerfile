#++++++++++++++++++++++++++++++++++++++
# PHP application Docker container
#++++++++++++++++++++++++++++++++++++++

FROM php:7.2.14-fpm

ARG DEBIAN_FRONTEND=noninteractive

# Install required libraries and apps
RUN apt-get update && apt-get upgrade -y --no-install-recommends apt-utils \
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
    libzip-dev \
    wget \
    git \
    unzip \
    zip

# Install Php extensions
RUN docker-php-ext-install -j$(nproc) \
    bz2 \
    bcmath \
    calendar \
    exif \
    gettext \
    pcntl \
    soap \
    shmop \
    mysqli \
    sockets \
    opcache \
    wddx \
    pgsql \
    pdo_mysql \
    pdo_pgsql \
    zip \
    && docker-php-ext-configure ldap \
        --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-configure imap \
        --with-kerberos \
        --with-imap-ssl \
    && docker-php-ext-install imap

# Install PECL php extensions
RUN yes '' | pecl install imagick && docker-php-ext-enable imagick \
    && pecl install memcached && docker-php-ext-enable memcached \
    && pecl install mongodb && docker-php-ext-enable mongodb \
    && pecl install redis && docker-php-ext-enable redis \
    && pecl install ast && docker-php-ext-enable ast \
    && pecl install xdebug-2.7.0beta1 && docker-php-ext-enable xdebug \
    && pecl install igbinary && docker-php-ext-enable igbinary \
    && pecl install psr && docker-php-ext-enable psr \
    && pecl install mcrypt-1.0.2 && docker-php-ext-enable mcrypt \
    && pecl install amqp && docker-php-ext-enable amqp \
    && pecl install yaml && docker-php-ext-enable yaml

# Install APCu and APC backward compatibility
RUN pecl install apcu \
    && pecl install apcu_bc \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

# Install Phalcon
ENV PHALCON_VERSION=3.4.2

RUN curl -sSL "https://codeload.github.com/phalcon/cphalcon/tar.gz/v${PHALCON_VERSION}" | tar -xz \
    && cd cphalcon-${PHALCON_VERSION}/build \
    && ./install \
    && cp ../tests/_ci/phalcon.ini $(php-config --configure-options | grep -o "with-config-file-scan-dir=\([^ ]*\)" | awk -F'=' '{print $2}') \
    && cd ../../ \
    && rm -r cphalcon-${PHALCON_VERSION}

# Install Swoole
RUN git clone https://github.com/swoole/swoole-src.git && \
    cd swoole-src && \
    phpize && \
    ./configure --enable-openssl --enable-sockets --enable-http2 --enable-mysqlnd --enable-async-redis && \
    make && make install && \
    cd ../ && \
    rm -r swoole-src && \
    docker-php-ext-enable swoole


# Install Blackfire
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

# Install TA-Lib
RUN wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
  tar -xvzf ta-lib-0.4.0-src.tar.gz && \
  cd ta-lib/ && \
  ./configure --prefix=/usr && \
  make && \
  make install

RUN rm -R ta-lib ta-lib-0.4.0-src.tar.gz

# Install Trader PHP Extension
RUN pecl install trader && docker-php-ext-enable trader

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
