#!/bin/bash

# Exit on any error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Variables
REPO_URL="https://github.com/morteerror404/RedTeamInfraDeveloper-CWL.git"
REPO_DIR="/opt/RedTeamInfraDeveloper-CWL"
PWNDROP_PORT=8080
EVILGINX_PORT=8443
APP_DIR="$REPO_DIR/App-web"

# Check for required tools
for cmd in git pwndrop evilginx ufw; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed. Please run setup_redteam_tools.sh first."
        exit 1
    fi
done

echo "Cloning repository..."
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists at $REPO_DIR. Pulling latest changes..."
    cd "$REPO_DIR"
    git pull
    cd -
else
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Configure pwndrop
echo "Configuring pwndrop to serve App-web on port $PWNDROP_PORT..."
if [ ! -d "$APP_DIR" ]; then
    echo "Error: App-web directory not found in $REPO_DIR."
    exit 1
fi

# Create pwndrop configuration
PWNDROP_CONFIG="/opt/pwndrop/pwndrop.ini"
cat > "$PWNDROP_CONFIG" <<EOF
[http]
listen_addr = 0.0.0.0:$PWNDROP_PORT
webroot = $APP_DIR
EOF

# Ensure pwndrop data directory exists
mkdir -p /opt/pwndrop/data
chown -R pwndrop:pwndrop /opt/pwndrop

# Start pwndrop in the background
echo "Starting pwndrop..."
pwndrop -c "$PWNDROP_CONFIG" &

# Configure evilginx
echo "Configuring evilginx on port $EVILGINX_PORT..."
# Create a basic evilginx config to serve on port 8443
EVILGINX_CONFIG="/opt/evilginx/config.yaml"
cat > "$EVILGINX_CONFIG" <<EOF
server:
  bind_addr: 0.0.0.0
  http_port: $EVILGINX_PORT
  dns_port: 53
phishlets:
  enabled: []
EOF

# Start evilginx in the background
echo "Starting evilginx..."
evilginx -c "$EVILGINX_CONFIG" &

# Configure firewall (ufw)
echo "Configuring firewall rules..."
ufw allow $PWNDROP_PORT/tcp comment "pwndrop HTTP"
ufw allow $EVILGINX_PORT/tcp comment "evilginx HTTP"
ufw allow 53 comment "evilginx DNS"
ufw enable

# Wait briefly to ensure services are up
sleep 5

# Verify services are running
if pgrep -f "pwndrop" >/dev/null; then
    echo "pwndrop is running on port $PWNDROP_PORT."
else
    echo "Error: pwndrop failed to start. Check logs in /opt/pwndrop."
    exit 1
fi

if pgrep -f "evilginx" >/dev/null; then
    echo "evilginx is running on port $EVILGINX_PORT."
else
    echo "Error: evilginx failed to start. Check logs."
    exit 1
fi

echo "Setup complete! Your application is served via:"
echo "- pwndrop: http://<server-ip>:$PWNDROP_PORT"
echo "- evilginx: https://<server-ip>:$EVILGINX_PORT"
echo "Ensure you configure evilginx phishlets as needed for your use case."
echo "Repository cloned to $REPO_DIR."