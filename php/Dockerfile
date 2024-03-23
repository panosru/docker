# Define ARG at the top to allow it to be available in all stages
ARG VERSION

##################
## Base Builder ##
##################
FROM php:${VERSION}-fpm-alpine as base-builder

# Set default environment variables used across stages
ENV APPLICATION_USER=application \
    APPLICATION_GROUP=application \
    APPLICATION_PATH=/app \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000

# Install the Docker PHP Extension Installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync

# Install system dependencies
RUN apk --no-cache upgrade && apk add --no-cache \
       autoconf g++ gcc make pkgconf re2c tar libtool linux-headers \
       curl-dev wget openssl-dev freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev imagemagick-dev \
       libmemcached-dev memcached postgresql-dev oniguruma-dev libxml2-dev \
       aspell-dev yaml-dev gettext-dev krb5-dev cyrus-sasl-dev zlib-dev libzip-dev git unzip logrotate supervisor \
       openldap-dev imap-dev tidyhtml-dev libxslt-dev pcre-dev gmp-dev rabbitmq-c-dev pcre pcre-tools

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
       bz2 bcmath calendar curl dba exif gettext pcntl soap shmop mysqli sockets \
       opcache pspell gmp pgsql pdo_mysql pdo_pgsql zip sockets sysvmsg sysvsem sysvshm tidy xsl \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install ldap \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && install-php-extensions @composer igbinary msgpack mongodb ast psr trader zephir_parser mailparse mcrypt xmlrpc amqp yaml redis apcu

# Conditionally install Phalcon for PHP 7.2 and above, including all PHP 8 versions
RUN if [ $(php -r 'echo PHP_MAJOR_VERSION;') -eq 7 ] && [ $(php -r 'echo PHP_MINOR_VERSION;') -ge 4 ]; then \
        install-php-extensions phalcon-5.4.0; \
    elif [ $(php -r 'echo PHP_MAJOR_VERSION;') -ge 8 ]; then \
        install-php-extensions phalcon; \
    fi

# Install Imagick from source since the PECL way is not yet compatible with PHP v8.3
RUN mkdir -p /usr/src/php/ext/imagick \
    &&  git clone --depth 1 https://github.com/Imagick/imagick.git /usr/src/php/ext/imagick \
    && docker-php-ext-install imagick

# Build memcached from source to enable flags
RUN git clone --depth 1 https://github.com/php-memcached-dev/php-memcached.git /usr/src/php/ext/memcached \
    && cd /usr/src/php/ext/memcached && phpize \
    && ./configure --enable-memcached --enable-memcached-session --enable-memcached-igbinary --enable-memcached-json --enable-memcached-msgpack --enable-memcached-sasl \
    && make && make install \
    && echo "extension=memcached.so" > $PHP_INI_DIR/conf.d/memcached.ini

# Install memcache depending on php version
RUN if [ $(php -r 'echo PHP_MAJOR_VERSION;') -eq 8 ]; then \
        pecl install memcache && docker-php-ext-enable --ini-name 40-memcache.ini memcache; \
    elif [ $(php -r 'echo PHP_MAJOR_VERSION;') -eq 7 ]; then \
        pecl install memcache-4.0.5.2 && docker-php-ext-enable --ini-name 40-memcache.ini memcache; \
    fi


# Build openswoole from source
RUN git clone https://github.com/openswoole/swoole-src.git /tmp/openswoole && cd /tmp/openswoole \
    && phpize && ./configure --enable-openssl --enable-http2 --enable-swoole --enable-mysqlnd --enable-swoole-json --enable-swoole-curl \
    && make && make install && docker-php-ext-enable openswoole

# Copy wddx source for later installation
COPY ./wddx /usr/src/php/ext/wddx

    # Build wddx from source
RUN docker-php-ext-install wddx
    
# Cleanup to reduce layer size
RUN apk del --purge autoconf g++ gcc make pkgconf re2c tar libtool linux-headers \
    && rm -rf /var/cache/apk/* /tmp/* /var/cache/apk/* /usr/src/php/ext/memcached /tmp/openswoole

############################
## Development Extensions ##
############################
FROM base-builder as dev-extensions-builder

ENV DEBUG_DIR /usr/local/lib/php/extensions/debug

RUN mkdir -p $DEBUG_DIR

# Install Xdebug
RUN install-php-extensions xdebug \
    && mv $(php -r "echo ini_get('extension_dir');")/xdebug.so ${DEBUG_DIR}/xdebug.so \
    && mv $PHP_INI_DIR/conf.d/*xdebug.ini ${DEBUG_DIR}/

# Install Blackfire
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/amd64/$version \
    && mkdir -p /tmp/blackfire \
    && tar -xvf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $DEBUG_DIR/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\n" > $DEBUG_DIR/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz


#######################
## Loaders extenions ##
#######################
FROM base-builder as loaders-extensions-builder

ENV LOADERS_DIR /usr/local/lib/php/extensions/loaders

RUN mkdir -p $LOADERS_DIR

# Install ionCube loader
RUN php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && php_extension_dir=$(php -r "echo ini_get('extension_dir');") \
    && cd /tmp \
    && curl -fSL 'http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz' -o ioncube.tar.gz \
    && mkdir -p ioncube \
    && tar -xf ioncube.tar.gz -C ioncube --strip-components=1 \
    && rm ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_$php_version.so $LOADERS_DIR/ioncube_loader_lin.so \
    && rm -r ioncube \
    && echo "zend_extension=$php_extension_dir/ioncube_loader_lin.so" > $LOADERS_DIR/00-ioncube.ini

# Install SourceGuardian loader
RUN php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && php_extension_dir=$(php -r "echo ini_get('extension_dir');") \
    && cd /tmp \
    && curl -fSL 'https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz' -o sg.tar.gz \
    && mkdir -p sg \
    && tar -xf sg.tar.gz -C sg \
    && rm sg.tar.gz \
    && mv sg/ixed.$php_version.lin $LOADERS_DIR/sourceguardian.so \
    && rm -r sg \
    && echo "extension=$php_extension_dir/sourceguardian.so" > $LOADERS_DIR/15-sourceguardian.ini

# Clean up
RUN rm -Rf /tmp/*


################
## Base Stage ##
################
FROM php:${VERSION}-fpm-alpine as base

# Install runtime dependencies required by PHP extensions
RUN apk --no-cache add \
    libbz2 libpng freetype libjpeg-turbo libwebp libxpm imagemagick-libs libxml2 aspell gmp icu-libs libldap libsasl zlib libzip \
    libmemcached-libs postgresql-libs c-client rabbitmq-c libgomp libpq lz4 lz4-libs tidyhtml libxslt libmcrypt snappy lz4 yaml

# Copy common setup from base-builder...
COPY --from=base-builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=base-builder /usr/local/bin/composer /usr/local/bin/
COPY --from=base-builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Set default environment variables used across stages
ENV APPLICATION_USER=application \
    APPLICATION_GROUP=application \
    APPLICATION_PATH=/app \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000

# Setup the application user and group
RUN addgroup -g "$APPLICATION_GID" "$APPLICATION_GROUP" \
    && adduser -D -u "$APPLICATION_UID" -G "$APPLICATION_GROUP" -h "/home/application" "$APPLICATION_USER"

# Set working directory
WORKDIR /var/www/html

# Set user
USER "$APPLICATION_USER"


#######################
## Development Stage ##
#######################
FROM base as development

# Now selectively copy only the development extensions
COPY --from=dev-extensions-builder /usr/local/lib/php/extensions/debug/* /tmp/debug/

# Switch to root to perform system files operations
USER root

# Move the files from the temp directory to their final destinations
    # Determine the PHP extension directory
RUN PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');") \
    # Determine the directory for additional .ini files
    && PHP_INI_DIR=$(php -i | grep 'Scan this dir for additional .ini files' | sed 's/.*=> //') \
    # Move .so files to the PHP extension directory
    && mv /tmp/debug/*.so "${PHP_EXT_DIR}/" \
    # Move .ini files to the PHP additional .ini files directory
    && mv /tmp/debug/*.ini "${PHP_INI_DIR}/" \
    # Cleanup the temp directory
    && rm -rf /tmp/debug/

# Set user
USER "$APPLICATION_USER"

# Set the environment context to development
ENV PROVISION_CONTEXT "development"


######################
## Production Stage ##
######################
FROM base as production

# Set the environment context to development
ENV PROVISION_CONTEXT "production"


####################################
## Development Stage With Loaders ##
####################################
FROM development as development-with-loaders

# Copy all files from the builder to a known temp directory
COPY --from=loaders-extensions-builder /usr/local/lib/php/extensions/loaders/* /tmp/loaders/

# Switch to root to perform system files operations
USER root

# Move the files from the temp directory to their final destinations
    # Determine the PHP extension directory
RUN PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');") \
    # Determine the directory for additional .ini files
    && PHP_INI_DIR=$(php -i | grep 'Scan this dir for additional .ini files' | sed 's/.*=> //') \
    # Move .so files to the PHP extension directory
    && mv /tmp/loaders/*.so "${PHP_EXT_DIR}/" \
    # Move .ini files to the PHP additional .ini files directory
    && mv /tmp/loaders/*.ini "${PHP_INI_DIR}/" \
    # Cleanup the temp directory
    && rm -rf /tmp/loaders/

# Set user
USER "$APPLICATION_USER"

###################################
## Production Stage With Loaders ##
###################################
FROM production as production-with-loaders

# Copy all files from the builder to a known temp directory
COPY --from=loaders-extensions-builder /usr/local/lib/php/extensions/loaders/* /tmp/loaders/

# Switch to root to perform system files operations
USER root

# Move the files from the temp directory to their final destinations
    # Determine the PHP extension directory
RUN PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');") \
    # Determine the directory for additional .ini files
    && PHP_INI_DIR=$(php -i | grep 'Scan this dir for additional .ini files' | sed 's/.*=> //') \
    # Move .so files to the PHP extension directory
    && mv /tmp/loaders/*.so "${PHP_EXT_DIR}/" \
    # Move .ini files to the PHP additional .ini files directory
    && mv /tmp/loaders/*.ini "${PHP_INI_DIR}/" \
    # Cleanup the temp directory
    && rm -rf /tmp/loaders/

# Set user
USER "$APPLICATION_USER"
