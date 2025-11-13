#!/usr/bin/env bash
set -e

CONFIG_PATH=/data/options.json
ENDPOINT=$(jq -r '.endpoint' "$CONFIG_PATH")
SETUP_KEY=$(jq -r '.token' "$CONFIG_PATH")
HOSTNAME=$(jq -r '.hostname' "$CONFIG_PATH")
HA_IP=$(jq -r '.homeassistant_ip' "$CONFIG_PATH")
HA_PORT=$(jq -r '.homeassistant_port' "$CONFIG_PATH")
USE_SSL=$(jq -r '.use_ssl' "$CONFIG_PATH")

NETBIRD_DIR=/data/netbird
mkdir -p "$NETBIRD_DIR"

# Symlink for Netbird persistent storage
if [ ! -L /var/lib/netbird ]; then
    echo "[INFO] Linking /var/lib/netbird to $NETBIRD_DIR"
    rm -rf /var/lib/netbird
    ln -s "$NETBIRD_DIR" /var/lib/netbird
fi

# Function to generate nginx config dynamically
create_nginx_conf() {
    local PROTOCOL="http"
    if [ "$USE_SSL" = "true" ]; then
        PROTOCOL="https"
    fi

    echo "[INFO] Creating nginx configuration on port 8123..."
    cat << EOF > /etc/nginx/nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen 8123;

        server_name localhost;

        location / {
            proxy_pass ${PROTOCOL}://$HA_IP:$HA_PORT;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            # WebSocket support for Home Assistant UI
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
EOF
}

# Generate nginx.conf
create_nginx_conf

echo "[INFO] Starting Nginx in foreground..."
nginx -g 'daemon off;' &

echo "[INFO] Starting NetBird..."
echo " - Endpoint: $ENDPOINT"
echo " - Hostname: $HOSTNAME"
echo " - Proxying to HA at $HA_IP:$HA_PORT (SSL: $USE_SSL)"

# Start NetBird daemon
/usr/bin/netbird service run &

sleep 3

# Check if already connected
CONNECTED_NETWORK=$(/usr/bin/netbird networks list | grep 'Status: Selected' || true)

if [ -n "$CONNECTED_NETWORK" ]; then
    echo "[INFO] Already connected to a network, skipping 'netbird up'"
else
    echo "[INFO] Not connected, running 'netbird up'..."
    /usr/bin/netbird up --management-url "$ENDPOINT" --setup-key "$SETUP_KEY" --hostname "$HOSTNAME"
fi

wait
