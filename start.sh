#!/bin/bash

# Startup script for website monitoring app
# Runs status checker in background and nginx in foreground

echo "Starting Website Monitoring App..."

# Run the status check script once immediately to generate initial data
echo "Running initial status check..."
/usr/local/bin/check_status.sh

# Ensure status.json has correct permissions
if [ -f /usr/share/nginx/html/status.json ]; then
    chmod 644 /usr/share/nginx/html/status.json
    echo "Set permissions on status.json"
fi

# Start the status checker loop in the background
# Runs every 60 seconds
(
    while true; do
        sleep 60
        echo "Running scheduled status check..."
        /usr/local/bin/check_status.sh
        # Ensure status.json has correct permissions after each update
        if [ -f /usr/share/nginx/html/status.json ]; then
            chmod 644 /usr/share/nginx/html/status.json
        fi
    done
) &

echo "Status checker started (running every 60 seconds)"
echo "Starting nginx web server..."

# Start nginx in the foreground (so container doesn't exit)
nginx -g "daemon off;"
