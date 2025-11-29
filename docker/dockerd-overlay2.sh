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

# Configure Docker daemon via UCI (init script generates /tmp/dockerd/daemon.json from UCI)
# All options are simple values, so UCI can handle them without needing a custom JSON file
uci set dockerd.globals.storage_driver="overlay2"
uci set dockerd.globals.data_root="/opt/docker/"
uci set dockerd.globals.log_level="debug"
uci set dockerd.globals.iptables="0"
uci set dockerd.globals.ip6tables="0"
uci delete dockerd.globals.alt_config_file 2>/dev/null || true
uci commit dockerd

