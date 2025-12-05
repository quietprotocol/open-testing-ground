# OpenMANET Ansible Deployment

This directory contains Ansible playbooks and roles for deploying and managing OpenMANET gateway configurations.

## Overview

The Ansible setup provides:
- **Idempotent deployments** - Safe to run multiple times
- **Multi-device management** - Manage multiple devices from a single inventory
- **Modular roles** - Each component is a separate, reusable role
- **Better error handling** - Clear error messages and rollback capabilities
- **Dry-run capability** - Test changes with `--check` before applying

## Quick Start

1. **Copy and configure inventory:**
```bash
   cp inventory/hosts.example.yml inventory/hosts.yml
   # Edit inventory/hosts.yml with your device information
```

2. **Run the main playbook:**
```bash
   ansible-playbook playbooks/site.yml
```

3. **Run specific roles:**
```bash
   ansible-playbook playbooks/site.yml --tags docker
   ansible-playbook playbooks/site.yml --tags gps
   ansible-playbook playbooks/site.yml --tags atak
   ```

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── group_vars/              # Group variables
│   └── all.yml              # Global variables
├── inventory/               # Inventory files
│   ├── hosts.example.yml    # Example inventory
│   └── hosts.yml            # Your inventory (gitignored)
├── playbooks/               # Playbooks
│   ├── site.yml             # Main playbook
│   ├── atak.yml             # TAK Server deployment
│   ├── docker.yml           # Docker configuration
│   ├── gps.yml              # GPS setup
│   ├── opentakserver.yml    # OpenTAKServer deployment
│   └── openwrt.yml          # OpenWrt firmware build
└── roles/                   # Ansible roles
    ├── atak/                # TAK Server role
    ├── docker/               # Docker role
    ├── gps/                 # GPS role
    ├── opentakserver/       # OpenTAKServer role
    └── openwrt/             # OpenWrt build role
```

## Inventory Configuration

Edit `inventory/hosts.yml` to configure your devices:

```yaml
all:
  children:
    openmanet_devices:
      hosts:
        gateway:
          ansible_host: 192.168.1.1
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
        mesh_point:
          ansible_host: 192.168.1.2
          ansible_user: root
          ansible_password: your_password
```

## Roles

### docker

Configures Docker storage driver and data directory on OpenWrt devices.

**Tasks:**
- Configures Docker to use overlay2 storage driver
- Sets up Docker data directory on USB storage or overlay
- Creates Docker storage image file
- Configures Docker daemon

**Variables** (defined in `roles/docker/defaults/main.yml`):
- `docker_storage_driver`: Storage driver (default: `overlay2`)
- `docker_data_root`: Docker data directory (default: `/opt/docker`)
- `docker_image_path`: Path to Docker storage image (default: `/overlay/docker.ext4`)
- `docker_image_size_gb`: Size of Docker storage image in GB (default: `20`)
- `docker_usb_device`: USB device for Docker storage (default: `/dev/sda1`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

**Note:** After deployment, restart Docker: `ansible openmanet_devices -m shell -a "/etc/init.d/dockerd restart"`

### gps

Configures GPS initialization for WM1302 Pi Hat with Quectel L76K GNSS module.

**Tasks:**
- Deploys GPS initialization script
- Configures GPS to run on boot via `/etc/rc.local`
- Sets up GPIO pins for GPS reset and wake control

**Variables** (defined in `roles/gps/defaults/main.yml`):
- `gps_serial_port`: GPS serial port (default: `/dev/ttyAMA0`)
- `gps_reset_gpio`: GPIO pin for GPS reset (default: `25`)
- `gps_wake_gpio`: GPIO pin for GPS wake (default: `24`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

**Note:** GPS setup requires WM1302 Pi Hat hardware. The GPS will start automatically on boot.

### atak

Deploys TAK Server installation scripts and Docker Compose configuration.

**Tasks:**
- Creates TAK Server directory structure
- Copies setup scripts (`setup.sh`, `certDP.sh`, `shareCerts.sh`)
- Copies `docker-compose.arm.yml` configuration
- Verifies deployment

**Variables** (defined in `roles/atak/defaults/main.yml`):
- `tak_server_dir`: TAK Server directory (default: `~/tak-server`)
- `tak_server_scripts_dir`: Scripts directory (default: `~/tak-server/scripts`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

**Note:** After deployment, you still need to run `setup.sh` on the device manually or via Ansible ad-hoc command.

### opentakserver

Deploys OpenTAKServer Docker Compose configuration.

**Tasks:**
- Creates OpenTAKServer directory
- Backs up existing `compose.yaml` if present
- Copies `compose.yaml` configuration
- Verifies deployment

**Variables** (defined in `roles/opentakserver/defaults/main.yml`):
- `opentakserver_dir`: OpenTAKServer directory (default: `~/ots-docker`)
- `compose_backup`: Whether to backup existing compose.yaml (default: `true`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

**Note:** After deployment, you need to run `make up` or `docker compose up -d` on the device.

### openwrt

Complete OpenWrt firmware build workflow. This role handles the entire build process from cloning the repository to pulling build artifacts back to your local machine.

**Important:** All build tasks run on a **REMOTE build server** via SSH. The playbook executes locally but delegates all build operations to the remote server.

**Complete Workflow:**

1. **Clone Repository**: Clones [OpenMANET/openwrt](https://github.com/OpenMANET/openwrt) repository on remote build server
2. **Checkout Branch**: Checks out specified branch (default: `release-1.5`)
3. **Initialize Build**: Runs `morse_setup.sh` to initialize build environment
4. **Apply Docker Config**: Applies `docker_diffconfig` to enable Docker support
5. **Download Sources**: Downloads all required source packages
6. **Build Firmware**: Compiles the firmware image with Docker support (uses 16 cores by default)
7. **Pull Artifacts**: Downloads build artifacts (images, logs, packages) from remote server to local machine

**Usage:**

```bash
# Full build workflow
ansible-playbook playbooks/openwrt.yml

# Run specific steps using tags
ansible-playbook playbooks/openwrt.yml --tags clone      # Just clone repo
ansible-playbook playbooks/openwrt.yml --tags setup       # Setup and morse
ansible-playbook playbooks/openwrt.yml --tags diffconfig  # Apply docker config
ansible-playbook playbooks/openwrt.yml --tags download    # Download sources
ansible-playbook playbooks/openwrt.yml --tags build       # Build firmware
ansible-playbook playbooks/openwrt.yml --tags artifacts   # Pull artifacts
```

**Variables** (defined in `roles/openwrt/defaults/main.yml`):

**Build Server Connection (REMOTE):**
- `openwrt_build_server`: Build server hostname or IP (default: from `build_server_host`)
- `openwrt_build_user`: Build server username (default: `ubuntu`)
- `openwrt_build_ssh_key`: SSH key path (default: `~/.ssh/id_rsa_proxmox_vms`)
- `openwrt_build_path`: OpenWrt repository path on remote server (default: `/home/ubuntu/source/openwrt/`)

**Repository Configuration:**
- `openwrt_repo_url`: Repository URL (default: `https://github.com/OpenMANET/openwrt.git`)
- `openwrt_repo_branch`: Branch to checkout (default: `release-1.5`)
- `openwrt_build_config`: Morse setup config identifier (default: `ekh01`)

**Build Configuration:**
- `openwrt_build_jobs`: Parallel build jobs (default: `16` cores)
- `openwrt_build_verbose`: Verbose level (default: `sc`)

**Local Artifacts:**
- `openwrt_local_artifacts_dir`: Local directory for build artifacts (default: `../artifacts/openwrt`)
- `openwrt_local_build_log`: Local path for build log (default: `{{ openwrt_local_artifacts_dir }}/build.log`)

**Example Configuration** (in `group_vars/all.yml`):

```yaml
# Build server connection
build_server_host: openmanet.marmal.duckdns.org
build_server_user: ubuntu
build_ssh_key: ~/.ssh/id_rsa_proxmox_vms

# OpenWrt build configuration
openwrt_repo_branch: release-1.5
openwrt_build_config: ekh01
openwrt_build_jobs: 16  # Adjust based on CPU cores
```

**Build Artifacts:**

After a successful build, artifacts are downloaded to:
- `artifacts/openwrt/build.log` - Build log file
- `artifacts/openwrt/*.img.gz` - Firmware images
- `artifacts/openwrt/packages/` - Built packages directory

**Note:** 
- All build operations run on the **REMOTE build server** via SSH delegation
- The build server must be accessible via SSH from your local machine
- The build server should have sufficient disk space (20GB+ recommended) and CPU cores
- **Build time**: The build step typically takes **15+ minutes** (can vary based on hardware and selected packages)
- Build progress is checked every 30 seconds - the playbook will wait for completion
- Build artifacts are automatically downloaded to your local machine after completion

**Flashing Firmware:**

The openwrt role also supports flashing firmware images to devices. You can flash images that are either:
- **Local on the device**: Already present on the device filesystem
- **Local on your machine**: Will be transferred to the device before flashing

**Flash Variables:**
- `openwrt_flash_image_path`: Path to firmware image on the device (e.g., `/tmp/firmware.img.gz`)
- `openwrt_flash_image_local`: Local path on Ansible control machine (will be transferred to device)
- `openwrt_flash_keep_settings`: Preserve settings during flash (default: `true`)
- `openwrt_flash_device_path`: Temporary path on device for transferred images (default: `/tmp/firmware.img.gz`)

**Flash Examples:**

```bash
# Flash image that's already on the device
ansible-playbook playbooks/site.yml --tags flash -e "openwrt_flash_image_path=/tmp/firmware.img.gz"

# Flash image from local machine (will be transferred first)
ansible-playbook playbooks/site.yml --tags flash -e "openwrt_flash_image_local=../artifacts/openwrt/firmware.img.gz"

# Flash without preserving settings
ansible-playbook playbooks/site.yml --tags flash \
  -e "openwrt_flash_image_local=../artifacts/openwrt/firmware.img.gz" \
  -e "openwrt_flash_keep_settings=false"

# Flash to specific device
ansible-playbook playbooks/site.yml --tags flash --limit gateway \
  -e "openwrt_flash_image_local=../artifacts/openwrt/firmware.img.gz"
```

**Flash Process:**
1. Validates image configuration (either `openwrt_flash_image_path` or `openwrt_flash_image_local` must be set)
2. Transfers image to device if using `openwrt_flash_image_local`
3. Verifies image exists on device
4. Flashes firmware using `sysupgrade` (with `-k` flag to preserve settings if enabled)
5. Waits for device to reboot (device will disconnect during flash)
6. Verifies device comes back online after reboot

**Important Notes:**
- Flashing will **reboot the device** - ensure you have console access or reliable network connectivity
- The device will be unreachable for 1-5 minutes during the flash and reboot process
- Settings are preserved by default (`openwrt_flash_keep_settings: true`)
- Use `sysupgrade` compatible images (`.img.gz` files with `-sysupgrade` in the name)

## Ad-Hoc Commands

Test connectivity:

```bash
ansible openmanet_devices -m ping
```

Check Docker status:

```bash
ansible openmanet_devices -m command -a "docker info | grep 'Storage Driver'"
```

Check GPS status:

```bash
ansible openmanet_devices -m command -a "/etc/init.d/gps-init status"
```

Run TAK Server setup (after deploying scripts):

```bash
ansible openmanet_devices -m shell -a "cd ~/tak-server && ./scripts/setup.sh"
```

Check OpenTAKServer status:

```bash
ansible openmanet_devices -m shell -a "cd ~/ots-docker && docker compose ps"
```

## Best Practices

1. **Use tags** to run specific roles or tasks:
   ```bash
   ansible-playbook playbooks/site.yml --tags docker
   ```

2. **Test with --check** before applying changes:
   ```bash
   ansible-playbook playbooks/site.yml --check
   ```

3. **Use --limit** to target specific devices:
   ```bash
   ansible-playbook playbooks/site.yml --limit gateway
   ```

4. **Review changes** with --diff:
   ```bash
   ansible-playbook playbooks/site.yml --diff
   ```

5. **Use vault** for sensitive data:
```bash
   ansible-vault encrypt group_vars/all.yml
```

## Troubleshooting

### Connection Issues

If you can't connect to devices:

   ```bash
# Test SSH connectivity
ansible openmanet_devices -m ping

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa

# Test with verbose output
   ansible-playbook playbooks/site.yml -vvv
   ```

### Permission Issues

If tasks fail with permission errors:

```bash
# Ensure you're using the correct user
ansible openmanet_devices -m shell -a "whoami"

# Check sudo access (if needed)
ansible openmanet_devices -m shell -a "sudo whoami" --become
```

### Role-Specific Issues

- **Docker**: Check Docker daemon is running: `ansible openmanet_devices -m shell -a "/etc/init.d/dockerd status"`
- **GPS**: Check serial port: `ansible openmanet_devices -m shell -a "ls -la /dev/ttyAMA0"`
- **OpenWrt Build**: Check build log: `tail -100 artifacts/openwrt/build.log`

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [OpenMANET OpenWrt Repository](https://github.com/OpenMANET/openwrt)
- [OpenMANET Documentation](https://openmanet.github.io/docs/)
