# Open Ansible Deployment

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
   ansible-playbook playbooks/site.yml --tags openwrt
   ansible-playbook playbooks/site.yml --tags docker
   ansible-playbook playbooks/site.yml --tags gps
   ansible-playbook playbooks/site.yml --tags govtak
   ansible-playbook playbooks/site.yml --tags ots
   ansible-playbook playbooks/site.yml --tags cloudtak
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
│   ├── govtak.yml           # GovTAK Server deployment
│   ├── docker.yml           # Docker configuration
│   ├── gps.yml              # GPS setup
│   ├── gps-reset.yml        # GPS reset
│   ├── opentakserver.yml    # OpenTAKServer deployment
│   └── openmanet-image.yml  # OpenWrt firmware build
└── roles/                   # Ansible roles
    ├── cloudtak/           # CloudTAK deployment role
    ├── govtak/              # GovTAK Server role
    ├── docker/               # Docker role
    ├── gps/                 # GPS role
    ├── gps-reset/           # GPS reset role
    ├── opentakserver/       # OpenTAKServer role
    ├── opentakserver-dted/  # OpenTAKServer DTED upload role
    ├── opentakserver-packages/  # OpenTAKServer packages upload role
    ├── opentakserver-users/  # OpenTAKServer user creation role
    ├── openmanet-image/     # OpenWrt build role
    └── usbc-gadget/         # USB-C gadget mode role
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

Each role has its own documentation. See the README.md file in each role directory for detailed information:

- **[cloudtak](roles/cloudtak/README.md)** - Deploys CloudTAK, a browser-based TAK client and ETL tool
- **[docker](roles/docker/README.md)** - Configures Docker storage driver and data directory on OpenWrt devices
- **[gps](roles/gps/README.md)** - Configures GPS initialization for WM1302 Pi Hat with Quectel L76K GNSS module
- **[gps-reset](roles/gps-reset/README.md)** - Removes GPS initialization configuration and puts the GPS module into standby mode
- **[govtak](roles/govtak/README.md)** - Deploys GovTAK Server installation scripts and Docker Compose configuration
- **[opentakserver](roles/opentakserver/README.md)** - Deploys OpenTAKServer Docker Compose configuration
- **[opentakserver-dted](roles/opentakserver-dted/README.md)** - Uploads DTED files from GitHub releases to OpenTAKServer
- **[opentakserver-packages](roles/opentakserver-packages/README.md)** - Uploads ATAK plugin APK files from GitHub releases to OpenTAKServer
- **[opentakserver-users](roles/opentakserver-users/README.md)** - Creates users in OpenTAKServer using the API
- **[openmanet-image](roles/openmanet-image/README.md)** - Complete OpenWrt firmware build workflow
- **[usbc-gadget](roles/usbc-gadget/README.md)** - Configures USB-C gadget mode for connecting EUDs to the mesh network

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
- [OpenMANET Firmware Repository](https://github.com/OpenMANET/firmware)
- [OpenMANET Documentation](https://openmanet.github.io/docs/)
