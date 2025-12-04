#!/bin/bash
# Deploy GPS init script to OpenWrt device
# Usage: ./deploy_gps_init.sh [device-ip] [device-password]
# If .env file exists in the project root, it will be used for defaults

# Get the project root directory (parent of this script's directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env file from project root if it exists (for default values)
if [ -f "${PROJECT_ROOT}/.env" ]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
fi

# Use command-line arguments or fall back to .env defaults
DEVICE_IP="${1:-${DEVICE_IP}}"
DEVICE_USER="${DEVICE_USER:-root}"
DEVICE_PASS="${2:-${DEVICE_PASS}}"

# Check if required parameters are provided
if [ -z "$DEVICE_IP" ] || [ -z "$DEVICE_PASS" ]; then
    echo "Usage: $0 [device-ip] [device-password]"
    echo ""
    echo "You can either:"
    echo "  1. Provide IP and password as arguments: $0 192.168.1.1 mypassword"
    echo "  2. Create a .env file in the project root with DEVICE_IP and DEVICE_PASS"
    echo "  3. Copy .env.example to .env in the project root and update the values"
    exit 1
fi
SCRIPT_NAME="gps-init"
TARGET_PATH="/etc/init.d/gps-init"

echo "=== Deploying GPS init script to device ==="
echo "Device: ${DEVICE_USER}@${DEVICE_IP}"
echo ""

# Check if gps-init exists locally
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "ERROR: $SCRIPT_NAME not found in current directory"
    exit 1
fi

# Copy script to device
echo "Step 1: Copying $SCRIPT_NAME to device..."
sshpass -p "$DEVICE_PASS" scp -o StrictHostKeyChecking=no "$SCRIPT_NAME" "${DEVICE_USER}@${DEVICE_IP}:${TARGET_PATH}" || {
    echo "ERROR: Failed to copy script"
    exit 1
}
echo "✓ Script copied to ${TARGET_PATH}"

# Make script executable
echo ""
echo "Step 2: Making script executable..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "chmod +x ${TARGET_PATH}" || {
    echo "ERROR: Failed to make script executable"
    exit 1
}
echo "✓ Script is now executable"

# Enable script to run at boot
echo ""
echo "Step 3: Enabling script to run at boot..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "/etc/init.d/gps-init enable" || {
    echo "WARNING: Failed to enable script (may already be enabled)"
}
echo "✓ Script enabled for boot"

# Check current status
echo ""
echo "Step 4: Checking script status..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "ls -lh ${TARGET_PATH} && echo '' && /etc/init.d/gps-init status" || {
    echo "WARNING: Could not check status"
}

# Ask if user wants to start it now
echo ""
echo "=== Deployment complete ==="
echo ""
echo "The GPS init script is now installed and enabled."
echo ""
echo "To start GPS now (without reboot):"
echo "  ssh ${DEVICE_USER}@${DEVICE_IP}"
echo "  /etc/init.d/gps-init start"
echo ""
echo "To control GPS:"
echo "  /etc/init.d/gps-init on     # Turn GPS ON"
echo "  /etc/init.d/gps-init off    # Turn GPS OFF"
echo "  /etc/init.d/gps-init status # Check GPS status"
echo ""
read -p "Start GPS now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting GPS..."
    sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "/etc/init.d/gps-init start"
    echo ""
    echo "GPS started. Check status:"
    sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "/etc/init.d/gps-init status"
fi

