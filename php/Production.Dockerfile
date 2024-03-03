ARG VERSION

# Extend from the PHP Base Image
FROM panosru/php:$VERSION-base

# Set the environment context to production
ENV PROVISION_CONTEXT "production"

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
