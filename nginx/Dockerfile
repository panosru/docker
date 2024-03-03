# Start from the Nginx image based on Alpine
FROM nginx:alpine

# Install necessary packages
RUN apk --no-cache add logrotate dcron curl

# Ensure /var/www/html exists
RUN mkdir -p /var/www/html

# Adjust permissions and ownership of Nginx directories
# Necessary since we're switching to a non-root user
RUN chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/www/html

# Switch back to the root user to perform operations that require root privileges
USER root

# Copy the Nginx configuration template and logrotate configuration
COPY default.nginx /etc/nginx/conf.d/default.template
COPY nginx-logrotate /etc/logrotate.d/nginx

# Correct permissions for the logrotate configuration and create directories
RUN chmod 0644 /etc/logrotate.d/nginx && \
    mkdir -p /var/lib/logrotate && \
    touch /var/lib/logrotate/logrotate.status && \
    mkdir -p /etc/nginx/custom.conf.d

# Copy the custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ensure the entrypoint script and subsequent commands run as the non-root user
USER nginx

ENTRYPOINT ["/entrypoint.sh"]
