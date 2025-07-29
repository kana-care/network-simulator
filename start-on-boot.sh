#!/bin/bash

# Check if running as root for tc commands
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    exit 1
fi

# Hardcoded values
SCRIPT_PATH="/home/kana/network-simulator.sh"
SERVICE_NAME="network-simulator"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "Creating systemd service for ${SCRIPT_PATH}..."

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Script $SCRIPT_PATH does not exist!"
    exit 1
fi

# Check if script is executable
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "Warning: Script $SCRIPT_PATH is not executable. Making it executable..."
    chmod +x "$SCRIPT_PATH"
fi

# Create the systemd service file
echo "Creating service file at $SERVICE_FILE..."
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Auto-generated service for network-simulator.sh
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service
echo "Enabling service..."
sudo systemctl enable "$SERVICE_NAME.service"

# Check if service was created successfully
if sudo systemctl is-enabled "$SERVICE_NAME.service" > /dev/null 2>&1; then
    echo "Success! Service $SERVICE_NAME has been created and enabled."
    echo "The service will run at boot."
    echo ""
    echo "Useful commands:"
    echo "  Start service now: sudo systemctl start $SERVICE_NAME"
    echo "  Check status: sudo systemctl status $SERVICE_NAME"
    echo "  View logs: sudo journalctl -u $SERVICE_NAME"
    echo "  Disable service: sudo systemctl disable $SERVICE_NAME"
else
    echo "Error: Failed to create or enable the service."
    exit 1
fi
