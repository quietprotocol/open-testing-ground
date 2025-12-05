#!/bin/bash
# Deploy Docker diffconfig to OpenWrt build repository
# Usage: ./deploy_docker_diffconfig.sh [build-server] [build-server-user] [ssh-key-path|password]
# If .env file exists in the project root, it will be used for defaults
#
# This script uploads docker_diffconfig to boards/common/docker_diffconfig
# in the OpenWrt build repository on the build server.

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
BUILD_SERVER="${1:-${BUILD_SERVER_HOST}}"
BUILD_USER="${2:-${BUILD_SERVER_USER}}"
SSH_KEY_OR_PASS="${3:-${BUILD_SSH_KEY:-${BUILD_SERVER_PASS}}}"
OPENWRT_PATH="${BUILD_SERVER_PATH:-/home/ubuntu/source/openwrt/}"

# Check if required parameters are provided
if [ -z "$BUILD_SERVER" ] || [ -z "$BUILD_USER" ]; then
    echo "Usage: $0 [build-server] [build-server-user] [ssh-key-path|password]"
    echo ""
    echo "You can either:"
    echo "  1. Provide server, user, and key/password as arguments: $0 build.example.com ubuntu ~/.ssh/id_rsa"
    echo "  2. Create a .env file in the project root with BUILD_SERVER_HOST, BUILD_SERVER_USER, and BUILD_SSH_KEY or BUILD_SERVER_PASS"
    echo "  3. Copy .env.example to .env in the project root and update the values"
    exit 1
fi

FILE_NAME="docker_diffconfig"
TARGET_PATH="${OPENWRT_PATH}boards/common/docker_diffconfig"

echo "=== Deploying Docker diffconfig to build server ==="
echo "Server: ${BUILD_USER}@${BUILD_SERVER}"
echo "Target: ${TARGET_PATH}"
echo ""

# Check if docker_diffconfig exists locally
if [ ! -f "$FILE_NAME" ]; then
    echo "ERROR: $FILE_NAME not found in current directory"
    exit 1
fi

# Determine authentication method
if [ -n "$SSH_KEY_OR_PASS" ] && [ -f "$SSH_KEY_OR_PASS" ]; then
    # SSH key authentication
    USE_SSH_KEY=true
    SSH_KEY="$SSH_KEY_OR_PASS"
    echo "Using SSH key authentication: $SSH_KEY"
else
    # Password authentication (or no auth if key file doesn't exist)
    USE_SSH_KEY=false
    BUILD_PASS="$SSH_KEY_OR_PASS"
    if [ -n "$BUILD_PASS" ]; then
        echo "Using password authentication"
    else
        echo "WARNING: No SSH key or password provided. Attempting connection without explicit auth."
    fi
fi

# Create target directory if it doesn't exist
echo ""
echo "Step 1: Ensuring target directory exists..."
if [ "$USE_SSH_KEY" = true ]; then
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${BUILD_USER}@${BUILD_SERVER}" "mkdir -p ${OPENWRT_PATH}boards/common" || {
        echo "ERROR: Failed to create target directory"
        exit 1
    }
else
    if [ -n "$BUILD_PASS" ]; then
        sshpass -p "$BUILD_PASS" ssh -o StrictHostKeyChecking=no "${BUILD_USER}@${BUILD_SERVER}" "mkdir -p ${OPENWRT_PATH}boards/common" || {
            echo "ERROR: Failed to create target directory"
            exit 1
        }
    else
        ssh -o StrictHostKeyChecking=no "${BUILD_USER}@${BUILD_SERVER}" "mkdir -p ${OPENWRT_PATH}boards/common" || {
            echo "ERROR: Failed to create target directory"
            exit 1
        }
    fi
fi
echo "✓ Target directory ready"

# Copy file to build server
echo ""
echo "Step 2: Copying $FILE_NAME to build server..."
if [ "$USE_SSH_KEY" = true ]; then
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$FILE_NAME" "${BUILD_USER}@${BUILD_SERVER}:${TARGET_PATH}" || {
        echo "ERROR: Failed to copy file"
        exit 1
    }
else
    if [ -n "$BUILD_PASS" ]; then
        sshpass -p "$BUILD_PASS" scp -o StrictHostKeyChecking=no "$FILE_NAME" "${BUILD_USER}@${BUILD_SERVER}:${TARGET_PATH}" || {
            echo "ERROR: Failed to copy file"
            exit 1
        }
    else
        scp -o StrictHostKeyChecking=no "$FILE_NAME" "${BUILD_USER}@${BUILD_SERVER}:${TARGET_PATH}" || {
            echo "ERROR: Failed to copy file"
            exit 1
        }
    fi
fi
echo "✓ File copied to ${TARGET_PATH}"

# Verify the file
echo ""
echo "Step 3: Verifying file on build server..."
if [ "$USE_SSH_KEY" = true ]; then
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${BUILD_USER}@${BUILD_SERVER}" "ls -lh ${TARGET_PATH} && echo '' && head -20 ${TARGET_PATH}" || {
        echo "WARNING: Could not verify file"
    }
else
    if [ -n "$BUILD_PASS" ]; then
        sshpass -p "$BUILD_PASS" ssh -o StrictHostKeyChecking=no "${BUILD_USER}@${BUILD_SERVER}" "ls -lh ${TARGET_PATH} && echo '' && head -20 ${TARGET_PATH}" || {
            echo "WARNING: Could not verify file"
        }
    else
        ssh -o StrictHostKeyChecking=no "${BUILD_USER}@${BUILD_SERVER}" "ls -lh ${TARGET_PATH} && echo '' && head -20 ${TARGET_PATH}" || {
            echo "WARNING: Could not verify file"
        }
    fi
fi

echo ""
echo "=== Deployment complete ==="
echo ""
echo "The docker_diffconfig file has been uploaded to:"
echo "  ${BUILD_USER}@${BUILD_SERVER}:${TARGET_PATH}"
echo ""
echo "You can now use this diffconfig in your OpenWrt build by:"
echo "  1. Copying it to your build config: cp ${TARGET_PATH} .config"
echo "  2. Or applying it: cat ${TARGET_PATH} >> .config"
echo "  3. Then run: make defconfig"

