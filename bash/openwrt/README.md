# OpenWrt Build Instructions

This directory contains documentation for building custom OpenWrt firmware images for OpenMANET devices.

## Overview

This guide covers building OpenWrt images with Docker support and other customizations for OpenMANET gateways. The build process uses the OpenMANET fork of OpenWrt with custom patches and configurations.

## Prerequisites

- Ubuntu build machine (or compatible Linux distribution)
- Sufficient disk space (at least 20GB free recommended)
- Git installed
- Build tools (will be installed during setup)

## References

- [OpenWrt Build System Documentation](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem)
- [OpenMANET OpenWrt Repository](https://github.com/OpenMANET/openwrt)
- [OpenMANET OpenWrt Release 1.4.1](https://github.com/OpenMANET/openwrt/tree/release-1.4.1)

## Building Images

### Step 1: Clone the Repository

```bash
git clone https://github.com/OpenMANET/openwrt.git
cd openwrt
```

### Step 2: Checkout Release Version

```bash
git checkout release-1.4.1
```

### Step 3: Run Morse Setup Script

The Morse setup script initializes the build environment and configures the build for your specific device:

```bash
./scripts/morse_setup.sh -i -b ekh01
```

**Parameters:**
- `-i`: Initialize the build environment
- `-b ekh01`: Build configuration identifier (adjust for your device)

### Step 4: Configure Build Options

Open the menu configuration interface to select packages and features:

```bash
make menuconfig
```

**Important**: This is where you select Docker and other utilities (see Docker Configuration section below).

**Filesystem Size**: You can resize the root filesystem partition by navigating to:
- **Target Images → Root filesystem partition size (in MiB)**

Set this value based on your device's storage capacity and requirements. Larger values allow for more installed packages and data storage.

### Step 5: Download Sources

Download all required source packages:

```bash
make download
```

This step may take some time depending on your internet connection.

### Step 6: Build the Image

Start the build process:

```bash
make -j16 V=sc 2>&1 | tee log.txt
```

**Parameters:**
- `-j16`: Use 16 parallel jobs (adjust based on your CPU cores)
- `V=sc`: Verbose output with source code context
- `2>&1 | tee log.txt`: Save build output to `log.txt` for troubleshooting

**Note**: The build process can take long time depending on your hardware and selected packages.

### Step 7: Locate the Built Image

After successful build, the firmware image will be located at:

```bash
/home/ubuntu/source/openwrt/bin/targets/bcm27xx/bcm2711/openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-squashfs-sysupgrade.img.gz
```

**Path breakdown:**
- `bcm27xx`: Broadcom 27xx target (Raspberry Pi)
- `bcm2711`: Specific SoC variant
- `ekh01`: Build configuration identifier
- `squashfs-sysupgrade`: Filesystem type and upgrade format

### Step 8: Transfer the Image

Copy the built image to your local machine:

**Option 1: Using .env file (recommended)**

If you've configured the build server settings in the project root `.env` file:

```bash
# Load environment variables
source ../.env

# Transfer the image
scp -i ${BUILD_SSH_KEY} \
  ${BUILD_SERVER_USER}@${BUILD_SERVER_HOST}:${BUILD_SERVER_PATH}openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-squashfs-sysupgrade.img.gz \
  ${BUILD_LOCAL_PATH}openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-docker-squashfs-sysupgrade.img.gz
```

**Option 2: Manual command**

```bash
scp -i ~/.ssh/<your-ssh-key> \
  <user>@<build-server>:/path/to/openwrt/bin/targets/bcm27xx/bcm2711/openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-squashfs-sysupgrade.img.gz \
  ~/path/to/destination/openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-docker-squashfs-sysupgrade.img.gz
```

**Replace placeholders:**
- `<your-ssh-key>` - Path to your SSH private key
- `<user>` - Username on the build server
- `<build-server>` - Hostname or IP of the build server
- `/path/to/openwrt/...` - Actual path to the built image on the build server
- `~/path/to/destination/...` - Destination path on your local machine

**Note**: Configure build server settings in the project root `.env` file:
- `BUILD_SERVER_USER` - Username on build server
- `BUILD_SERVER_HOST` - Build server hostname or IP
- `BUILD_SERVER_PATH` - Path to OpenWrt build output directory
- `BUILD_SSH_KEY` - Path to SSH private key for build server
- `BUILD_LOCAL_PATH` - Local destination directory for firmware images

## Docker Configuration

To include Docker support in your OpenWrt build, configure the following packages in `make menuconfig`:

### Utilities

Navigate to **Utilities** and enable:

- **docker** - Docker container runtime
- **docker-compose** - Docker Compose orchestration tool
- **dockerd** - Docker daemon

### Docker Kernel Support

Under **Utilities → dockerd**, enable:

- **kernel support** - Enable optional kernel support for docker

### Docker Network Support

Under **Utilities → dockerd → Network**, enable:

- **macvlan** - MACVLAN network driver (required for Docker networking)

### Docker Storage Support

Under **Utilities → dockerd → Storage**, enable:

- **ext3** - ext3 filesystem support
- **ext4** - ext4 filesystem support

### LuCI Docker Management

For web-based Docker management, enable LuCI applications:

**LuCI → 1. Collections:**
- **luci-lib-docker** - Docker library for LuCI

**LuCI → 3. Applications:**
- **luci-app-dockerman** - Docker management web interface

### Verification

After building with Docker support, verify on the device:

```bash
docker --version
docker-compose --version
```

## Flashing

### Over-the-Air (OTA) Upgrade

The `squashfs-sysupgrade` image format is designed for OTA upgrades that preserve system settings.

**Important**: Always backup your configuration before flashing!

1. **Access LuCI web interface:**
   ```
   http://<device-ip>
   ```

2. **Navigate to System → Backup / Flash Firmware**

3. **Upload the `.img.gz` file**

4. **Select "Keep settings"** to preserve your configuration

5. **Click "Flash image"**

### Manual Flashing

For initial installation or recovery, flash directly to the SD card:

```bash
# Extract the image
gunzip openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-squashfs-sysupgrade.img.gz

# Write to SD card (replace /dev/sdX with your SD card device)
sudo dd if=openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-squashfs-sysupgrade.img of=/dev/sdX bs=4M status=progress
```

**Warning**: Double-check the device path to avoid overwriting your system disk!

### Preserving Settings

When upgrading via sysupgrade, your settings are preserved by default. The following are retained:

- Network configuration (`/etc/config/network`)
- Wireless configuration (`/etc/config/wireless`)
- Firewall rules (`/etc/config/firewall`)
- Installed packages (if using overlay filesystem)
- Custom files in `/etc/` and `/root/`

## Troubleshooting

### Build Fails

1. **Check build log:**
   ```bash
   tail -100 log.txt
   ```

2. **Common issues:**
   - Missing dependencies: Run `./scripts/morse_setup.sh -i` again
   - Network issues: Check internet connection for `make download`
   - Disk space: Ensure sufficient free space (20GB+)
   - Memory: Build may require 4GB+ RAM

### Image Too Large

If the image exceeds your device's storage:

1. Remove unnecessary packages in `make menuconfig`
2. Use `squashfs` compression (already enabled)
3. Consider removing LuCI if not needed

### Docker Not Working After Flash

1. **Verify Docker packages are installed:**
   ```bash
   opkg list-installed | grep docker
   ```

2. **Check Docker daemon:**
   ```bash
   /etc/init.d/dockerd status
   ```

3. **Review Docker configuration:**
   See the [Docker README](../docker/README.md) for Docker setup and troubleshooting.

### Build Environment Issues

If the build environment becomes corrupted:

```bash
# Clean build directory
make clean

# Re-run setup
./scripts/morse_setup.sh -i -b ekh01

# Re-download sources
make download
```

## Build Output Location

All build artifacts are located in:

```
bin/targets/<target>/<subtarget>/
```

For Raspberry Pi 4 (bcm2711):
```
bin/targets/bcm27xx/bcm2711/
```

Common files:
- `*-squashfs-sysupgrade.img.gz` - Upgrade image (preserves settings)
- `*-squashfs-factory.img.gz` - Factory image (clean install)
- `*-rootfs.tar.gz` - Root filesystem archive
- `packages/` - Built packages directory

## Next Steps

After building and flashing:

1. **Configure Docker storage** - See [Docker README](../docker/README.md)
2. **Install TAK Server** - See [ATAK README](../atak/README.md)
3. **Set up GPS** - See [GPS README](../gps/README.md)

## Notes

- Build times vary significantly based on hardware
- The build process is CPU and I/O intensive
- Keep the build log for troubleshooting failed builds
- Always test images in a safe environment before deploying to production devices

