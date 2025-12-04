# TAK Server for OpenWrt

This directory contains modified scripts and configuration for running [TAK Server](https://github.com/Cloud-RF/tak-server) on OpenWrt devices.

## Origin

This setup is based on the [Cloud-RF/tak-server](https://github.com/Cloud-RF/tak-server) project, which provides a Docker-based TAK Server installation. The scripts in this directory have been modified to work with OpenWrt's BusyBox environment and resource constraints.

## Prerequisites

### OpenWrt Device Requirements

- OpenWrt device with Docker support
- At least 8GB RAM recommended
- Sufficient storage for Docker images and TAK server data
- Network interface configured and accessible

### Docker Setup

Before installing TAK Server, ensure Docker is properly configured on OpenWrt:

1. **Docker Storage Configuration**: Use the optimized Docker storage setup script:

   ```bash
   # Deploy the dockerd-overlay2.sh script
   cd ../docker
   ./deploy_dockerd_overlay2.sh
   ```

   This script:
   - Configures Docker to use `overlay2` storage driver
   - Optimizes for OpenWrt's filesystem (USB storage preferred, loopback fallback)
   - Disables bridge netfilter to allow Docker inter-container communication

2. **Verify Docker is running**:

   ```bash
   docker ps
   ```

## Installation

### Step 0: Install Required Packages

On your OpenWrt device, install the required packages:

```bash
opkg update
opkg install git-http git openssh-client bash unzip coreutils-sha1sum htop
```

**Packages:**
- `git-http` - Git with HTTP/HTTPS support
- `git` - Git version control
- `openssh-client` - SSH client for Git operations
- `bash` - Bash shell (required by setup scripts)
- `unzip` - ZIP file extraction
- `coreutils-sha1sum` - SHA1 checksum utility

### Step 1: Clone Cloud-RF TAK Server

On your OpenWrt device, clone the original repository:

```bash
cd ~
git clone https://github.com/Cloud-RF/tak-server.git
cd tak-server
```

### Step 2: Download TAK Server ZIP

Download the official TAK Server Docker ZIP file from [tak.gov/products/tak-server](https://tak.gov/products/tak-server) and place it in the `tak-server` directory on your device.

**Copy from your local machine via SCP:**

```bash
# Replace <device-ip> with your device IP address
scp takserver-docker-5.5-RELEASE-58.zip root@<device-ip>:/root/tak-server/
```


**Note**: This setup has only been tested with `takserver-docker-5.5-RELEASE-58.zip`.

### Step 3: Overlay Modified Scripts

Copy the modified scripts from this repository to replace the originals:

**Use the deployment script (recommended):**

```bash
# From your development machine
cd /path/to/OpenMANET-testing-ground/atak
./deploy_scripts.sh [openwrt-ip]
```

The script will:
- Copy all modified scripts to the device
- Make them executable
- Verify the deployment



### Step 4: Run Setup

On the OpenWrt device:

```bash
cd ~/tak-server
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup script will:

- Auto-detect architecture (ARM64 for most OpenWrt devices)
- Generate secure passwords (BusyBox-compatible)
- Configure TAK Server with appropriate memory allocation (6GB default)
- Start Docker containers (TAK server + PostgreSQL)
- Generate certificates
- Wait for services to fully initialize

**Note**: The setup process takes 5-10 minutes on OpenWrt due to resource constraints. Be patient during the initialization phase.

## Script Modifications

### `setup.sh`

**Changes from original:**

- **BusyBox compatibility**: Replaced `sha1sum`, `fold`, `zip` commands with BusyBox alternatives
- **Password generation**: Fixed to meet TAK complexity requirements (15+ chars, uppercase, lowercase, number, special char)
- **Wait logic**: Improved retry mechanism for TAK server initialization (accounts for slow startup on OpenWrt)
- **Memory allocation**: Default set to 6GB (6000000 kB) instead of 4GB

**Key features:**

- Auto-detects ARM64 architecture and uses `docker-compose.arm.yml`
- Generates secure random passwords
- Waits for TAK API service to fully start before completing

### `certDP.sh`

**Changes from original:**

- Replaced `zip` command with Python `zipfile` module (BusyBox doesn't include `zip`)
- Creates ATAK/iTAK compatible data packages (.zip files)

### `shareCerts.sh`

**Changes from original:**

- Added `.p12` file copying in addition to `.zip` packages
- Serves certificates via Python HTTP server on port 12345

## Post-Installation

### Generate user certs and create data package

```bash
docker exec -it -w /opt/tak/certs tak-server-tak-1 ./makeCert.sh client "YOURCLIENT"
./scripts/certDP.sh "YOURCLIENT"
./scripts/shareCerts.sh
```

### Access WebTAK

After successful installation, access the WebTAK interface at:

```text
https://<openwrt-ip>:8443
```

**Important**: You must import the `admin.p12` certificate into your browser first (default password: `atakatak`).

### Firewall Configuration

The installation assumes a permissive firewall configuration. If you need to restrict access, ensure port 8443 (and optionally 8444, 8089) is allowed in `/etc/config/firewall`.

### Container Management

**Start containers:**

```bash
cd ~/tak-server
docker-compose -f docker-compose.arm.yml up -d
```

**Stop containers:**

```bash
cd ~/tak-server
docker-compose -f docker-compose.arm.yml down
```

**View logs:**

```bash
cd ~/tak-server
docker-compose -f docker-compose.arm.yml logs -f tak
```

**Access container shell:**

```bash
docker exec -it tak-server-tak-1 bash
```

## Troubleshooting

### Port 8443 Not Accessible

If WebTAK is not accessible:

1. **Check if TAK API is fully started**:

   ```bash
   docker exec tak-server-tak-1 netstat -tlnp | grep 8443
   ```

   If no output, wait 2-3 more minutes for the API service to initialize.

2. **Check Docker port mapping**:

   ```bash
   docker-compose -f docker-compose.arm.yml ps
   netstat -tlnp | grep 8443
   ```

3. **Check firewall**:

   ```bash
   iptables -L INPUT -n -v | grep 8443
   ```

4. **Verify bridge netfilter is disabled**:

   ```bash
   sysctl net.bridge.bridge-nf-call-iptables
   ```
   Should return `0`. If not, ensure `/usr/bin/dockerd-overlay2.sh` is configured to run at boot.

### Database Connection Issues

If TAK server can't connect to PostgreSQL:

1. **Verify bridge netfilter is disabled** (see above)

2. **Check database container is running**:

   ```bash
   docker-compose -f docker-compose.arm.yml ps db
   ```

3. **Test connectivity from TAK container**:

   ```bash
   docker exec tak-server-tak-1 bash -c 'timeout 3 bash -c "echo > /dev/tcp/tak-database/5432" && echo "DB_CONNECT_SUCCESS" || echo "DB_CONNECT_FAILED"'
   ```

### Slow Startup

TAK Server takes 5-10 minutes to fully start on OpenWrt devices. This is normal due to:

- Limited CPU resources
- Filesystem I/O overhead (multiple layers: f2fs → loopback → overlayfs → Docker overlay2)
- Java service initialization

Be patient and monitor logs:

```bash
docker-compose -f docker-compose.arm.yml logs -f tak | grep -i "started\|error"
```

## Files Modified

- `scripts/setup.sh` - Main installation script
- `scripts/certDP.sh` - Certificate data package creator
- `scripts/shareCerts.sh` - Certificate sharing server
- `docker-compose.arm.yml` - Docker Compose configuration with `network: host` for builds (allows package downloads during build)

## Memory Configuration

Memory allocation is controlled via `setup.sh`. The default is set to 6GB (6000000 kB), which allocates:

- **CONFIG_MAX_HEAP**: ~170 MB
- **API_MAX_HEAP**: ~950 MB
- **MESSAGING_MAX_HEAP**: ~950 MB
- **PLUGIN_MANAGER_MAX_HEAP**: ~200 MB
- **RETENTION_MAX_HEAP**: ~200 MB

To change this, edit `scripts/setup.sh` and modify the `mem` variable (line ~268).

## Network Ports

TAK Server uses the following ports:

- **8443** - WebTAK HTTPS interface
- **8444** - Federation HTTPS
- **8446** - Certificate HTTPS
- **8089** - CoT (Cursor on Target) stream
- **9000-9001** - Internal services

Ensure these ports are available and not blocked by firewall rules.

## References

- [Cloud-RF/tak-server](https://github.com/Cloud-RF/tak-server) - Original repository
- [TAK Product Center](https://tak.gov) - Official TAK documentation
- [OpenWrt Docker Documentation](https://openwrt.org/docs/guide-user/virtualization/docker)

## License

This setup is based on Cloud-RF/tak-server which is licensed under MIT. See the original repository for license details.
