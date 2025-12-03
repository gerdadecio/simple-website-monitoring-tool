FROM nginx:alpine

# Install curl, bash, and bc for status checking
RUN apk add --no-cache curl bash bc

# Copy HTML file and set permissions
COPY index.html /usr/share/nginx/html/
RUN chmod 644 /usr/share/nginx/html/index.html && \
    chmod 755 /usr/share/nginx/html

# Copy configuration file (both for script and web access)
COPY config.json /usr/local/etc/monitor-config.json
COPY config.json /usr/share/nginx/html/config.json
RUN chmod 644 /usr/local/etc/monitor-config.json && \
    chmod 644 /usr/share/nginx/html/config.json

# Copy status check script
COPY check_status.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/check_status.sh

# Copy startup script
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 80

CMD ["/usr/local/bin/start.sh"]
