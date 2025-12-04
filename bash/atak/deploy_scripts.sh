#!/bin/bash
# Deploy modified TAK Server scripts to OpenWrt device
# Usage: ./deploy_scripts.sh [device-ip] [device-password]
# If .env file exists in the project root, it will be used for defaults

# Get the project root directory (two levels up from this script's directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

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
SCRIPTS_DIR="scripts"
TARGET_SCRIPTS_DIR="~/tak-server/scripts"
TARGET_ROOT="~/tak-server"

echo "=== Deploying TAK Server scripts and config to device ==="
echo "Device: ${DEVICE_USER}@${DEVICE_IP}"
echo ""

# Check if scripts directory exists locally
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "ERROR: $SCRIPTS_DIR directory not found in current directory"
    exit 1
fi

# Check if required scripts exist
REQUIRED_SCRIPTS=("setup.sh" "certDP.sh" "shareCerts.sh")
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        echo "ERROR: Required script $SCRIPTS_DIR/$script not found"
        exit 1
    fi
done

# Check if docker-compose.arm.yml exists
if [ ! -f "docker-compose.arm.yml" ]; then
    echo "ERROR: docker-compose.arm.yml not found in current directory"
    exit 1
fi

# Copy scripts to device
echo "Step 1: Copying scripts to device..."
for script in "${REQUIRED_SCRIPTS[@]}"; do
    echo "  - Copying $script..."
    sshpass -p "$DEVICE_PASS" scp -o StrictHostKeyChecking=no "$SCRIPTS_DIR/$script" "${DEVICE_USER}@${DEVICE_IP}:${TARGET_SCRIPTS_DIR}/" || {
        echo "ERROR: Failed to copy $script"
        exit 1
    }
done
echo "✓ All scripts copied to ${TARGET_SCRIPTS_DIR}"

# Copy docker-compose.arm.yml to device
echo ""
echo "Step 2: Copying docker-compose.arm.yml to device..."
sshpass -p "$DEVICE_PASS" scp -o StrictHostKeyChecking=no "docker-compose.arm.yml" "${DEVICE_USER}@${DEVICE_IP}:${TARGET_ROOT}/" || {
    echo "ERROR: Failed to copy docker-compose.arm.yml"
    exit 1
}
echo "✓ docker-compose.arm.yml copied to ${TARGET_ROOT}"

# Make scripts executable
echo ""
echo "Step 3: Making scripts executable..."
for script in "${REQUIRED_SCRIPTS[@]}"; do
    sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "chmod +x ${TARGET_SCRIPTS_DIR}/${script}" || {
        echo "ERROR: Failed to make $script executable"
        exit 1
    }
done
echo "✓ All scripts are now executable"

# Verify deployment
echo ""
echo "Step 4: Verifying deployment on device..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" << 'REMOTE_EOF'
echo "Scripts in ~/tak-server/scripts:"
ls -lh ~/tak-server/scripts/*.sh 2>/dev/null || echo "No .sh files found"
echo ""
echo "docker-compose.arm.yml:"
ls -lh ~/tak-server/docker-compose.arm.yml 2>/dev/null || echo "docker-compose.arm.yml not found"
REMOTE_EOF

echo ""
echo "=== Deployment complete ==="
echo ""
echo "The modified TAK Server scripts and docker-compose.arm.yml are now installed on the device."
echo ""
echo "To run setup:"
echo "  ssh ${DEVICE_USER}@${DEVICE_IP}"
echo "  cd ~/tak-server"
echo "  ./scripts/setup.sh"
echo ""
