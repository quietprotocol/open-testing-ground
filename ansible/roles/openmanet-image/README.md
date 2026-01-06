# openmanet-image

Complete OpenWrt firmware build workflow. This role handles the entire build process from cloning the repository to pulling build artifacts back to your local machine.

**Important:** All build tasks run on a **REMOTE build server** via SSH. The playbook executes locally but delegates all build operations to the remote server.

## Complete Workflow

1. **Clone Repository**: Clones [OpenMANET/firmware](https://github.com/OpenMANET/firmware) repository on remote build server
2. **Checkout Branch**: Checks out specified branch (default: `24.10` for 1.6.0-RC2)
3. **Initialize Build**: Runs `openmanet_setup.sh` to initialize build environment
4. **Apply Docker Config**: Applies `docker_diffconfig` to enable Docker support
5. **Download Sources**: Downloads all required source packages
6. **Build Firmware**: Compiles the firmware image with Docker support (uses 16 cores by default)
7. **Pull Artifacts**: Downloads build artifacts (images, logs, packages) from remote server to local machine

## Usage

```bash
# Full build workflow
ansible-playbook playbooks/openmanet-image.yml

# Run specific steps using tags
ansible-playbook playbooks/openmanet-image.yml --tags openwrt-clone      # Just clone repo
ansible-playbook playbooks/openmanet-image.yml --tags openwrt-setup       # Setup and morse
ansible-playbook playbooks/openmanet-image.yml --tags openwrt-diffconfig  # Apply docker config
ansible-playbook playbooks/openmanet-image.yml --tags openwrt-download    # Download sources
ansible-playbook playbooks/openmanet-image.yml --tags openwrt-build       # Build firmware
ansible-playbook playbooks/openmanet-image.yml --tags openwrt-artifacts   # Pull artifacts
```

## Variables

Variables are defined in `defaults/main.yml`:

### Build Server Connection (REMOTE)

- `openwrt_build_server`: Build server hostname or IP (default: from `build_server_host`)
- `openwrt_build_user`: Build server username (default: `ubuntu`)
- `openwrt_build_ssh_key`: SSH key path (default: `~/.ssh/id_rsa_proxmox_vms`)
- `openwrt_build_path`: OpenWrt repository path on remote server (default: `/home/ubuntu/source/openwrt/`)

### Repository Configuration

- `openwrt_repo_url`: Repository URL (default: `https://github.com/OpenMANET/firmware.git`)
- `openwrt_repo_branch`: Branch to checkout (default: `24.10` for 1.6.0-RC2)
- `openwrt_build_config`: Board identifier (default: `ekh-bcm2711` for RPi4, or `ekh01` which is still supported)

### Build Configuration

- `openwrt_build_jobs`: Parallel build jobs (default: `16` cores)
- `openwrt_build_verbose`: Verbose level (default: `sc`)

### Local Artifacts

- `openwrt_local_artifacts_dir`: Local directory for build artifacts (default: `../artifacts/openwrt`)
- `openwrt_local_build_log`: Local path for build log (default: `{{ openwrt_local_artifacts_dir }}/build.log`)

## Example Configuration

In `group_vars/all.yml`:

```yaml
# Build server connection
build_server_host: openmanet.marmal.duckdns.org
build_server_user: ubuntu
build_ssh_key: ~/.ssh/id_rsa_proxmox_vms

# OpenWrt build configuration
openwrt_repo_branch: 24.10  # or 1.6.0-RC2 tag
openwrt_build_config: ekh-bcm2711  # or ekh01 (still supported)
openwrt_build_jobs: 16  # Adjust based on CPU cores
```

## Build Artifacts

After a successful build, artifacts are downloaded to:

- `artifacts/openwrt/build.log` - Build log file
- `artifacts/openwrt/*.img.gz` - Firmware images
- `artifacts/openwrt/packages/` - Built packages directory

## Notes

- All build operations run on the **REMOTE build server** via SSH delegation
- The build server must be accessible via SSH from your local machine
- The build server should have sufficient disk space (20GB+ recommended) and CPU cores
- **Build time**: The build step typically takes **15+ minutes** (can vary based on hardware and selected packages)
- Build progress is checked every 30 seconds - the playbook will wait for completion
- Build artifacts are automatically downloaded to your local machine after completion

## Flashing Firmware

The openwrt role also supports flashing firmware images to devices. You can flash images that are either:

- **Local on the device**: Already present on the device filesystem
- **Local on your machine**: Will be transferred to the device before flashing

### Flash Variables

- `openwrt_flash_image_path`: Path to firmware image on the device (e.g., `/tmp/firmware.img.gz`)
- `openwrt_flash_image_local`: Local path on Ansible control machine (will be transferred to device)
- `openwrt_flash_keep_settings`: Preserve settings during flash (default: `true`)
- `openwrt_flash_device_path`: Temporary path on device for transferred images (default: `/tmp/firmware.img.gz`)

### Flash Examples

```bash
# Flash using auto-detected image from artifacts (recommended)
ansible-playbook playbooks/site.yml --tags openwrt-flash --limit gateway

# Flash image that's already on the device
ansible-playbook playbooks/site.yml --tags openwrt-flash --limit gateway \
  -e "openwrt_flash_image_path=/tmp/firmware.img.gz"

# Flash specific image from local machine
ansible-playbook playbooks/site.yml --tags openwrt-flash --limit gateway \
  -e "openwrt_flash_image_local=../artifacts/openwrt/firmware.img.gz"

# Flash without preserving settings
ansible-playbook playbooks/site.yml --tags openwrt-flash --limit gateway \
  -e "openwrt_flash_image_local=../artifacts/openwrt/firmware.img.gz" \
  -e "openwrt_flash_keep_settings=false"
```

### Flash Process

1. Validates image configuration (either `openwrt_flash_image_path` or `openwrt_flash_image_local` must be set)
2. Transfers image to device if using `openwrt_flash_image_local`
3. Verifies image exists on device
4. Flashes firmware using `sysupgrade` (with `-k` flag to preserve settings if enabled)
5. Waits for device to reboot (device will disconnect during flash)
6. Verifies device comes back online after reboot

### Important Notes

- Flashing will **reboot the device** - ensure you have console access or reliable network connectivity
- The device will be unreachable for 1-5 minutes during the flash and reboot process
- Settings are preserved by default (`openwrt_flash_keep_settings: true`)
- Use `sysupgrade` compatible images (`.img.gz` files with `-sysupgrade` in the name)

## Manual build

```bash
git clone https://github.com/OpenMANET/firmware.git
cd firmware
git checkout 24.10
./scripts/openmanet_setup.sh -i -b ekh-bcm2711
make menuconfig (this is where we select the docker under utils.)
make download
rm /home/ubuntu/source/openwrt/bin/targets/bcm27xx/bcm2711/openwrt-morse-2.8.5-morsemicro-mm6108-ekh01-squashfs-sysupgrade.img.gz 
rm log.txt
make -j16 V=sc 2>&1 | tee log.txt
```