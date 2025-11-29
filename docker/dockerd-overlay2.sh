#!/bin/sh
# Docker storage setup - mount ext4 loopback for overlay2
# This script mounts an ext4 loopback filesystem to /opt/docker
# so Docker can use overlay2 storage driver on OpenWrt (which has overlayfs root)
# Optimized with mount options for better performance

# Disable bridge netfilter to allow Docker inter-container communication
# This prevents OpenWrt's iptables from interfering with Docker's bridge network
sysctl -w net.bridge.bridge-nf-call-iptables=0 2>/dev/null || true

IMG_PATH="/overlay/docker.ext4"
TMP_MNT="/mnt/docker-ext4"
MNT_DIR="/opt/docker"
USB_DEVICE="/dev/sda1"

# Try USB drive first (if available) - eliminates loopback layer
if [ -b "${USB_DEVICE}" ] && ! mount | grep -q " on ${MNT_DIR} type ext4"; then
	echo "Using USB device ${USB_DEVICE} for Docker storage"
	mkdir -p "${MNT_DIR}"
	# Mount with optimized options: noatime, writeback, no barriers
	mount -o noatime,data=writeback,barrier=0 "${USB_DEVICE}" "${MNT_DIR}" 2>/dev/null && exit 0
fi

# Fallback to optimized loopback mount
# Create image if it doesn't exist
if [ ! -f "${IMG_PATH}" ]; then
	SIZE_GB=20
	dd if=/dev/zero of="${IMG_PATH}" bs=1M count=0 seek=$((SIZE_GB*1024))
	# Format with optimized options for better performance
	mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0 "${IMG_PATH}"
fi

# Mount ext4 loopback with optimized options
mkdir -p "${TMP_MNT}"
if ! mount | grep -q " on ${TMP_MNT} type ext4"; then
	# Optimized mount options:
	# - noatime: Don't update access times (faster)
	# - data=writeback: Faster writes (slightly less safe, but OK for Docker)
	# - barrier=0: Disable barriers for better performance on SD cards
	mount -o loop,noatime,data=writeback,barrier=0 "${IMG_PATH}" "${TMP_MNT}"
fi

# Bind mount to /opt/docker (overrides overlayfs)
mkdir -p "${MNT_DIR}"
if ! mount | grep -q " on ${MNT_DIR} type ext4"; then
	mount --bind "${TMP_MNT}" "${MNT_DIR}"
fi

# Configure Docker daemon.json to use overlay2
# OpenWrt uses /tmp/dockerd/daemon.json instead of /etc/docker/daemon.json
DOCKER_CONF_DIR="/tmp/dockerd"
DOCKER_CONF="${DOCKER_CONF_DIR}/daemon.json"
mkdir -p "${DOCKER_CONF_DIR}"

# Check if daemon.json exists and if it already has overlay2 configured
if [ ! -f "${DOCKER_CONF}" ] || ! grep -q "overlay2" "${DOCKER_CONF}" 2>/dev/null; then
	# Create or update daemon.json with overlay2 configuration
	cat > "${DOCKER_CONF}" << 'EOF'
{
  "storage-driver": "overlay2",
  "data-root": "/opt/docker/",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-level": "debug",
  "iptables": true,
  "ip6tables": false
}
EOF
fi

