#!/bin/sh
set -e

# Ensure /var/run/nginx (PID directory) exists and is owned by nginx
mkdir -p /var/run/nginx
chown nginx:nginx /var/run/nginx

# Change ownership of the Nginx log files
chown nginx:nginx /var/log/nginx/access.log /var/log/nginx/error.log

# Default values for environment variables
LOG_SIZE=${LOG_SIZE:-1}
LOG_ROTATE=${LOG_ROTATE:-1}
ADDITIONAL_DIRECTIVES=${ADDITIONAL_DIRECTIVES:-""}
CLIENT_MAX_BODY_SIZE=${CLIENT_MAX_BODY_SIZE:-100m}
FASTCGI_PASS=${FASTCGI_PASS:-""}

# Export variables for envsubst
export LOG_SIZE LOG_ROTATE ADDITIONAL_DIRECTIVES CLIENT_MAX_BODY_SIZE FASTCGI_PASS

# Apply configurations for logrotate and Nginx
envsubst '${LOG_SIZE} ${LOG_ROTATE} ${ADDITIONAL_DIRECTIVES}' < /etc/logrotate.d/nginx-logrotate.template > /etc/logrotate.d/nginx
envsubst '${CLIENT_MAX_BODY_SIZE},${FASTCGI_PASS}' < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf

# Correct permissions to ensure nginx user can read the configurations
chown root:root /etc/logrotate.d/nginx /etc/nginx/conf.d/default.conf
chmod 644 /etc/logrotate.d/nginx /etc/nginx/conf.d/default.conf

# Include custom Nginx configurations, if available
if [ -d /etc/nginx/custom.conf.d ]; then
    CONF_FILES=$(find /etc/nginx/custom.conf.d -type f -name "*.conf")
    if [ -n "$CONF_FILES" ]; then
        for f in $CONF_FILES; do
            echo "Including custom Nginx configuration: $f"
            . "$f"
        done
    else
        echo "No custom Nginx configuration files found in /etc/nginx/custom.conf.d"
    fi
fi

# Start cron daemon in the background
crond

# Switch to the nginx user for Nginx execution
exec su-exec nginx nginx -g 'daemon off;'
