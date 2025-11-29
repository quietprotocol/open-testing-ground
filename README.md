# OpenMANET Testing Ground

This repository contains setup scripts and documentation for configuring OpenMANET gateways running OpenWrt with Docker, GPS, and TAK Server support.

DISCLAIMER! THIS IS CLANKER TERRITORY. USE AT YOUR OWN RISK. NO REFUNDS.

## Initial Setup

Before running the deployment scripts, set up your device credentials:

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your actual device IP addresses and password
# The .env file is gitignored and will not be committed
```

The `.env` file supports:
- `DEVICE_IP` - Device IP address (used by all services)
- `DEVICE_USER` - SSH username (default: root)
- `DEVICE_PASS` - SSH password

## Setup Order

Follow these steps in order to set up a complete OpenMANET gateway:

### 1. Build and Flash OpenWrt Firmware

**Location**: [`openwrt/`](openwrt/)

Build a custom OpenWrt image with Docker support and flash it to your device.

**Steps:**
1. Build the OpenWrt image following instructions in [`openwrt/README.md`](openwrt/README.md)
2. Flash the image to your device (OTA upgrade or manual flash)
3. Verify the device boots and is accessible via SSH

**Prerequisites:**
- Ubuntu build machine
- OpenWrt device (Raspberry Pi 4 recommended)

**See**: [`openwrt/README.md`](openwrt/README.md) for detailed build instructions.

---

### 2. Configure Docker Storage

**Location**: [`docker/`](docker/)

Configure Docker to use the `overlay2` storage driver for optimal performance.

**Steps:**
```bash
cd docker
# Option 1: Use .env file (recommended)
# From project root: cp .env.example .env
# Edit .env with your device IP and password
./deploy_dockerd_overlay2.sh

# Option 2: Provide credentials as arguments
./deploy_dockerd_overlay2.sh <device-ip> <device-password>
```

This script:
- Configures Docker to use `overlay2` storage driver
- Sets up ext4 loopback filesystem for Docker data
- Makes the configuration persistent across reboots

**Prerequisites:**
- OpenWrt device with Docker packages installed (from step 1)
- SSH access to the device

**See**: [`docker/README.md`](docker/README.md) for detailed configuration and troubleshooting.

---

### 3. Install TAK Server

**Location**: [`atak/`](atak/)

Install and configure TAK Server for ATAK/iTAK client support.

**Steps:**
```bash
cd atak
# Option 1: Use .env file (recommended)
# From project root: cp .env.example .env
# Edit .env with your device IP and password
./deploy_scripts.sh

# Option 2: Provide credentials as arguments
./deploy_scripts.sh <device-ip> <device-password>
```

Then on the device:
```bash
cd ~/tak-server
./scripts/setup.sh
```

**Prerequisites:**
- OpenWrt device with Docker configured (from step 2)
- At least 8GB RAM recommended
- Sufficient storage for Docker images (~5GB+)
- TAK Server ZIP file from [tak.gov](https://tak.gov/products/tak-server)

**Important**: Docker must be properly configured (step 2) before installing TAK Server, as TAK Server runs in Docker containers.

**See**: [`atak/README.md`](atak/README.md) for detailed TAK Server installation and configuration.

---

### 4. Set Up GPS (Optional)

**Location**: [`gps/`](gps/)

Configure GPS initialization for WM1302 Pi Hat with Quectel L76K GNSS module.

**Steps:**
```bash
cd gps
# Option 1: Use .env file (recommended)
# From project root: cp .env.example .env
# Edit .env with your device IP and password
./deploy_gps_init.sh

# Option 2: Provide credentials as arguments
./deploy_gps_init.sh <device-ip> <device-password>
```

This script:
- Deploys GPS initialization script to the device
- Configures GPS to run on boot via `/etc/rc.local`
- Sets up GPIO pins for GPS reset and wake control

**Prerequisites:**
- OpenWrt device (from step 1)
- WM1302 Pi Hat with GPS module installed
- GPS antenna connected
- SSH access to the device

**Note**: GPS setup is independent and can be done at any time after OpenWrt is installed.

**See**: [`gps/README.md`](gps/README.md) for detailed GPS configuration and troubleshooting.

## Directory Structure

```
.
├── atak/             # TAK Server installation scripts
├── docker/           # Docker storage configuration
├── gps/              # GPS initialization setup
├── openwrt/          # OpenWrt firmware build instructions
└── README.md         # This file
```

## Verification

After completing all steps, verify your setup:

1. **OpenWrt**: Device boots and is accessible
   ```bash
   ssh root@[device-ip]
   ```

2. **Docker**: Docker uses overlay2 storage driver
   ```bash
   docker info | grep "Storage Driver"
   # Should show: Storage Driver: overlay2
   ```

3. **TAK Server**: WebTAK accessible
   ```bash
   # Access https://[device-ip]:8443
   # Import admin.p12 certificate first
   ```

4. **GPS**: GPS outputs NMEA data (if configured)
   ```bash
   cat /dev/ttyAMA0
   # Should show NMEA sentences
   ```

## Troubleshooting

If you encounter issues:

1. **OpenWrt issues**: See [`openwrt/README.md`](openwrt/README.md) troubleshooting section
2. **Docker issues**: See [`docker/README.md`](docker/README.md) troubleshooting section
3. **GPS issues**: See [`gps/README.md`](gps/README.md) troubleshooting section
4. **TAK Server issues**: See [`atak/README.md`](atak/README.md) troubleshooting section

## TODOs

### GPS

- Get GPS working
  - Why doesn't mine work on ttyS0?
  - [WM1302 Pi Hat GPS Discussion](https://forum.chirpstack.io/t/wm1302-pi-hat-built-in-gps/24124)

### ATAK

- GPS to COT forwarded
  - With and without server
  - [ATAK Push COTS](https://github.com/kylesayrs/ATAK_push_cots)
  - [PyTAK](https://github.com/snstac/pytak)

### UPS

- Get battery status working. Missing i2c stuff on openmanet?

### Ansible

- Because it's prettier than scripts.

- [https://github.com/gekmihesg/ansible-openwrt](https://github.com/gekmihesg/ansible-openwrt)
- [https://github.com/imp1sh/ansible_managemynetwork](https://github.com/imp1sh/ansible_managemynetwork)

### PTT

Some links

- [https://resilience-theatre.com/wiki/doku.php?id=secureptt:introduction](https://resilience-theatre.com/wiki/doku.php?id=secureptt:introduction)
- [https://github.com/skuep/AIOC?tab=readme-ov-file](https://github.com/skuep/AIOC?tab=readme-ov-file)
- [https://www.aliexpress.com/item/1005009672034522.html](https://www.aliexpress.com/item/1005009672034522.html)

### MediaMTX server

- [https://www.thetaksyndicate.org/mediamtx-video-server](https://www.thetaksyndicate.org/mediamtx-video-server)
- [https://www.thetaksyndicate.org/mediamtx-video-server](https://www.thetaksyndicate.org/mediamtx-video-server)

### Mumble

- [https://github.com/mumble-voip/mumble-docker](https://github.com/mumble-voip/mumble-docker)


## References

- [OpenMANET OpenWrt Repository](https://github.com/OpenMANET/openwrt)
- [OpenMANET Documentation](https://openmanet.github.io/docs/)
- [TAK Product Center](https://tak.gov)
- [Cloud-RF TAK Server](https://github.com/Cloud-RF/tak-server)

