#!/usr/bin/env bash
set -e

CONFIG_PATH=/data/options.json
ENDPOINT=$(jq -r '.endpoint' "$CONFIG_PATH")
SETUP_KEY=$(jq -r '.token' "$CONFIG_PATH")
HOSTNAME=$(jq -r '.hostname' "$CONFIG_PATH")
NGINX_PORT=$(jq -r '.nginx_port' "$CONFIG_PATH")

NETBIRD_DIR=/data/netbird
mkdir -p "$NETBIRD_DIR"

# Symlink for Netbird persistent storage
if [ ! -L /var/lib/netbird ]; then
    echo "[INFO] Linking /var/lib/netbird to $NETBIRD_DIR"
    rm -rf /var/lib/netbird
    ln -s "$NETBIRD_DIR" /var/lib/netbird
fi

# Home Assistant IP & port
HA_IP="127.0.0.1"
HA_PORT=8123

# Function to generate nginx config dynamically
create_nginx_conf() {
    echo "[INFO] Creating nginx configuration on port $NGINX_PORT..."
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
        listen $NGINX_PORT;

        server_name localhost;

        location / {
            proxy_pass https://$HA_IP:$HA_PORT;
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
echo " - Nginx Port: $NGINX_PORT"
echo " - Proxying to HA at $HA_IP:$HA_PORT"

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
