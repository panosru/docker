ARG VERSION

# Extend from the PHP Base Image
FROM panosru/php:$VERSION-base-loaders

# Install Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Install Blackfire
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

# Clean up
RUN pecl clear-cache \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /tmp/*

# Set the environment context to development
ENV PROVISION_CONTEXT "development"

# Define environment variables for the application user, group, path, and IDs
ENV APPLICATION_USER=application \
    APPLICATION_GROUP=application \
    APPLICATION_PATH=/app \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000

# Create the application group
RUN groupadd -g "$APPLICATION_GID" "$APPLICATION_GROUP" && \
    # Create the application user with specified home directory and shell
    useradd -u "$APPLICATION_UID" --home "/home/application" --create-home --shell /bin/bash --no-user-group "$APPLICATION_USER" && \
    # Assign the user to the application group
    usermod -g "$APPLICATION_GROUP" "$APPLICATION_USER" && \
    # Set the appropriate ownership and permissions for application directory
    mkdir -p /var/www/html && chown -R "$APPLICATION_USER":"$APPLICATION_GROUP" /var/www/html

# Set the working directory to /var/www/html
WORKDIR /var/www/html

USER "$APPLICATION_USER"