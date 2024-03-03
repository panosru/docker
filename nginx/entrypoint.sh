#!/bin/sh
set -e

# Default values for environment variables
LOG_SIZE=${LOG_SIZE:-1}
LOG_ROTATE=${LOG_ROTATE:-1}
ADDITIONAL_DIRECTIVES=${ADDITIONAL_DIRECTIVES:-""}
CLIENT_MAX_BODY_SIZE=${CLIENT_MAX_BODY_SIZE:-100m}
FASTCGI_PASS=${FASTCGI_PASS:-""}

# Export variables for envsubst
export LOG_SIZE LOG_ROTATE ADDITIONAL_DIRECTIVES CLIENT_MAX_BODY_SIZE FASTCGI_PASS

# Apply configurations for logrotate
envsubst '${LOG_SIZE} ${LOG_ROTATE} ${ADDITIONAL_DIRECTIVES}' < /etc/logrotate.d/nginx-logrotate.template > /etc/logrotate.d/nginx

# Apply configurations for Nginx
envsubst '${CLIENT_MAX_BODY_SIZE},${FASTCGI_PASS}' < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf

# Include custom Nginx configurations, if available
if [ -d /etc/nginx/custom.conf.d ]; then
    for f in /etc/nginx/custom.conf.d/*.conf; do
        echo "Including custom Nginx configuration: $f"
        . "$f"
    done
fi

# Start cron daemon in the background
crond -f &

# Display Nginx version for debugging purposes
nginx -v

# Execute Nginx in the foreground
exec nginx -g "daemon off;"
