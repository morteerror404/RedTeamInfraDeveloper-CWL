#!/bin/bash

# Exit on any error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to find installation directory
find_install_dir() {
    local binary_name="$1"
    local possible_dirs=(
        "/opt/$binary_name"
        "/usr/local/$binary_name"
        "/usr/share/$binary_name"
        "$HOME/$binary_name"
    )

    # First try which + readlink
    local binary_path=$(which "$binary_name" 2>/dev/null)
    if [ -n "$binary_path" ]; then
        local install_dir=$(readlink -f "$binary_path" | xargs dirname | xargs dirname)
        if [ -d "$install_dir" ]; then
            echo "$install_dir"
            return
        fi
    fi

    # Check common directories
    for dir in "${possible_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return
        fi
    done

    # Last resort: try to find from process
    local pid=$(pgrep -f "$binary_name" | head -n 1)
    if [ -n "$pid" ]; then
        local exe_path=$(readlink -f "/proc/$pid/exe")
        local install_dir=$(dirname "$exe_path" | xargs dirname)
        echo "$install_dir"
        return
    fi

    echo ""
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

# Find installation directories
PWNDROP_DIR=$(find_install_dir "pwndrop")
EVILGINX_DIR=$(find_install_dir "evilginx")

if [ -z "$PWNDROP_DIR" ]; then
    echo "Error: Could not determine pwndrop installation directory"
    exit 1
fi

if [ -z "$EVILGINX_DIR" ]; then
    echo "Error: Could not determine evilginx installation directory"
    exit 1
fi

echo "Found installations:"
echo "- pwndrop: $PWNDROP_DIR"
echo "- evilginx: $EVILGINX_DIR"

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
PWNDROP_CONFIG="$PWNDROP_DIR/pwndrop.ini"
cat > "$PWNDROP_CONFIG" <<EOF
[http]
listen_addr = 0.0.0.0:$PWNDROP_PORT
webroot = $APP_DIR
EOF

# Ensure pwndrop data directory exists
mkdir -p "$PWNDROP_DIR/data"
chown -R pwndrop:pwndrop "$PWNDROP_DIR"

# Start pwndrop in the background
echo "Starting pwndrop..."
pwndrop -c "$PWNDROP_CONFIG" &

# Configure evilginx
echo "Configuring evilginx on port $EVILGINX_PORT..."
# Create a basic evilginx config to serve on port 8443
EVILGINX_CONFIG="$EVILGINX_DIR/config.yaml"
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
    echo "Error: pwndrop failed to start. Check logs in $PWNDROP_DIR."
    exit 1
fi

if pgrep -f "evilginx" >/dev/null; then
    echo "evilginx is running on port $EVILGINX_PORT."
else
    echo "Error: evilginx failed to start. Check logs in $EVILGINX_DIR."
    exit 1
fi

echo "Setup complete! Your application is served via:"
echo "- pwndrop: http://<server-ip>:$PWNDROP_PORT"
echo "- evilginx: https://<server-ip>:$EVILGINX_PORT"
echo "Ensure you configure evilginx phishlets as needed for your use case."
echo "Repository cloned to $REPO_DIR."