#!/bin/bash
# Deploy OpenTAKServer compose.yaml to OpenWrt device
# Usage: ./deploy_compose.sh [device-ip] [device-password]
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

COMPOSE_FILE="compose.yaml"
TARGET_DIR="~/ots-docker"
TARGET_FILE="${TARGET_DIR}/compose.yaml"

echo "=== Deploying OpenTAKServer compose.yaml to device ==="
echo "Device: ${DEVICE_USER}@${DEVICE_IP}"
echo ""

# Check if compose.yaml exists locally
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: $COMPOSE_FILE not found in current directory"
    exit 1
fi

# Check if sshpass is available (required for password authentication)
if ! command -v sshpass &> /dev/null; then
    echo "ERROR: sshpass is required but not installed"
    echo "Install it with: brew install hudochenkov/sshpass/sshpass (macOS) or apt-get install sshpass (Linux)"
    exit 1
fi

# Ensure target directory exists on device
echo "Step 1: Ensuring target directory exists on device..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "mkdir -p ${TARGET_DIR}" || {
    echo "ERROR: Failed to create target directory"
    exit 1
}
echo "✓ Target directory ready"

# Backup existing compose.yaml if it exists
echo ""
echo "Step 2: Backing up existing compose.yaml (if present)..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" "
    if [ -f ${TARGET_FILE} ]; then
        cp ${TARGET_FILE} ${TARGET_FILE}.backup.\$(date +%Y%m%d_%H%M%S)
        echo '  - Backed up existing compose.yaml'
    else
        echo '  - No existing compose.yaml to backup'
    fi
" || {
    echo "WARNING: Failed to backup existing file (continuing anyway)"
}

# Copy compose.yaml to device
echo ""
echo "Step 3: Copying compose.yaml to device..."
sshpass -p "$DEVICE_PASS" scp -o StrictHostKeyChecking=no "$COMPOSE_FILE" "${DEVICE_USER}@${DEVICE_IP}:${TARGET_FILE}" || {
    echo "ERROR: Failed to copy compose.yaml"
    exit 1
}
echo "✓ compose.yaml copied to ${TARGET_FILE}"

# Verify deployment
echo ""
echo "Step 4: Verifying deployment on device..."
sshpass -p "$DEVICE_PASS" ssh -o StrictHostKeyChecking=no "${DEVICE_USER}@${DEVICE_IP}" << 'REMOTE_EOF'
echo "compose.yaml:"
ls -lh ~/ots-docker/compose.yaml 2>/dev/null || echo "compose.yaml not found"
echo ""
echo "File size and first few lines:"
if [ -f ~/ots-docker/compose.yaml ]; then
    wc -l ~/ots-docker/compose.yaml
    echo ""
    echo "Port mappings in compose.yaml:"
    grep -E "0\.0\.0\.0:[0-9]+:[0-9]+" ~/ots-docker/compose.yaml | head -10
else
    echo "ERROR: compose.yaml not found after deployment"
fi
REMOTE_EOF

echo ""
echo "=== Deployment complete ==="
echo ""
echo "The modified compose.yaml is now installed on the device."
echo ""
echo "To start OpenTAKServer:"
echo "  ssh ${DEVICE_USER}@${DEVICE_IP}"
echo "  cd ~/ots-docker"
echo "  make up"
echo ""
echo "Or using docker compose directly:"
echo "  docker compose -f compose.yaml up -d"
echo ""
echo "Access the Web UI at:"
echo "  HTTP:  http://${DEVICE_IP}:8880"
echo "  HTTPS: https://${DEVICE_IP}:8440"
echo ""

