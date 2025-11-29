#!/bin/bash
# Deploy Docker overlay2 storage setup script to OpenWrt device
# Usage: ./deploy_dockerd_overlay2.sh [device-ip] [device-password]
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
SCRIPT_NAME="dockerd-overlay2.sh"
TARGET_PATH="/usr/bin/dockerd-overlay2.sh"

echo "=== Deploying Docker overlay2 storage script to device ==="
echo "Device: ${DEVICE_USER}@${DEVICE_IP}"
echo ""

# Check if script exists locally
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

# Update rc.local to call the script
echo ""
echo "Step 3: Updating /etc/rc.local to call the script..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" << 'REMOTE_EOF'
# Check if already configured
if grep -q "dockerd-overlay2.sh" /etc/rc.local 2>/dev/null; then
    echo "✓ rc.local already configured"
else
    # Create new rc.local with the script call before exit 0
    cat > /etc/rc.local << 'EOF'
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

# Docker storage setup
/usr/bin/dockerd-overlay2.sh

exit 0
EOF
    echo "✓ rc.local updated"
fi
REMOTE_EOF

# Verify rc.local
echo ""
echo "Step 4: Verifying rc.local configuration..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "cat /etc/rc.local"

# Apply the script immediately (without reboot)
echo ""
echo "Step 5: Applying Docker overlay2 configuration..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" << 'REMOTE_EOF'
# Stop Docker if running
/etc/init.d/dockerd stop 2>/dev/null || true
sleep 2

# Run the mount and config script
/usr/bin/dockerd-overlay2.sh

# Start Docker
/etc/init.d/dockerd start
sleep 5
REMOTE_EOF

# Verify the setup
echo ""
echo "Step 6: Verifying configuration..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" << 'REMOTE_EOF'
echo "Mount status:"
mount | grep -E '/opt/docker|/mnt/docker-ext4' || echo "Mount not found"
echo ""
echo "Docker storage driver:"
docker info 2>/dev/null | grep 'Storage Driver' || echo "Docker not running or not accessible"
REMOTE_EOF

echo ""
echo "=== Deployment complete ==="
echo ""
echo "The Docker overlay2 storage script is now installed and configured."
echo "Configuration has been applied immediately - no reboot required."
echo ""
echo "On next boot, the script will run automatically via /etc/rc.local"

