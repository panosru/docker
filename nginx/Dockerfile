# Start from the Nginx image based on Alpine
FROM nginx:alpine

# Install necessary packages, including su-exec for privilege dropping
RUN apk --no-cache add logrotate dcron curl su-exec

# Ensure /var/www/html exists and adjust permissions as needed
RUN mkdir -p /var/www/html && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/www/html && \
    chmod 775 /var/cache/nginx /var/log/nginx /var/www/html

# Copy the Nginx and logrotate configuration templates
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.nginx /etc/nginx/conf.d/default.template
COPY nginx-logrotate /etc/logrotate.d/nginx-logrotate.template

# Copy the custom entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Start as root
ENTRYPOINT ["/entrypoint.sh"]
