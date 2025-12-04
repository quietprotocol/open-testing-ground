# OpenMANET Ansible Deployment

This directory contains Ansible playbooks and roles for deploying OpenMANET gateway configurations across multiple devices.

## Prerequisites

- Ansible 2.9 or later
- SSH access to your OpenWrt devices
- Python on the control machine (for Ansible)

## Installation

### Install Ansible

**macOS:**
```bash
brew install ansible
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install ansible
```

**Python pip:**
```bash
pip install ansible
```

## Configuration

### 1. Inventory Setup

Copy the example inventory file and update it with your device information:

```bash
cp inventory/hosts.example.yml inventory/hosts.yml
```

Edit `inventory/hosts.yml` with your device details:

```yaml
all:
  children:
    openmanet_devices:
      hosts:
        gateway1:
          ansible_host: 192.168.1.1
          ansible_user: root
          ansible_password: your_password_here
          # Or use SSH key:
          # ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

**Security Note:** For production use, consider:
- Using SSH keys instead of passwords
- Using Ansible Vault to encrypt sensitive data
- Using `ansible_ssh_private_key_file` in inventory

### 2. Using Ansible Vault (Recommended)

Create an encrypted vault file for passwords:

```bash
ansible-vault create inventory/group_vars/all/vault.yml
```

Add your passwords:
```yaml
ansible_password: your_password_here
```

Then reference it in your inventory or group_vars.

### 3. Variable Customization

Variables are defined in each role's `defaults/main.yml` file. To customize values:

- **For all devices**: Override in `group_vars/all.yml` or `host_vars/<hostname>.yml`
- **For specific devices**: Create `host_vars/<hostname>.yml` with device-specific values

Each role's default variables are documented in the Roles section below.

## Usage

### Deploy Everything

Deploy all configurations to all devices:

```bash
ansible-playbook playbooks/site.yml
```

### Deploy Specific Components

Deploy only Docker storage configuration:

```bash
ansible-playbook playbooks/docker.yml
```

Deploy only GPS initialization:

```bash
ansible-playbook playbooks/gps.yml
```

Deploy only TAK Server:

```bash
ansible-playbook playbooks/atak.yml
```

Deploy only OpenTAKServer:

```bash
ansible-playbook playbooks/opentakserver.yml
```

### Deploy to Specific Hosts

Deploy to a specific device:

```bash
ansible-playbook playbooks/site.yml --limit gateway1
```

Deploy to multiple specific devices:

```bash
ansible-playbook playbooks/site.yml --limit gateway1,gateway2
```

### Using Tags

Deploy only specific roles using tags:

```bash
# Only Docker-related tasks
ansible-playbook playbooks/site.yml --tags docker

# Only GPS-related tasks
ansible-playbook playbooks/site.yml --tags gps

# Only TAK Server-related tasks
ansible-playbook playbooks/site.yml --tags atak

# Only OpenTAKServer-related tasks
ansible-playbook playbooks/site.yml --tags ots
```

**Available Tags:**
- `docker` - Docker overlay2 storage configuration
- `gps` - GPS initialization
- `atak` - TAK Server deployment
- `ots` - OpenTAKServer deployment

**Examples:**
```bash
# Run only Docker role
ansible-playbook playbooks/site.yml --tags docker

# Run multiple roles
ansible-playbook playbooks/site.yml --tags docker,gps

# Skip a specific role
ansible-playbook playbooks/site.yml --skip-tags atak
```

### Check Mode (Dry Run)

Test changes without applying them:

```bash
ansible-playbook playbooks/site.yml --check
```

### Verbose Output

Get more detailed output:

```bash
ansible-playbook playbooks/site.yml -v    # Verbose
ansible-playbook playbooks/site.yml -vv   # More verbose
ansible-playbook playbooks/site.yml -vvv  # Debug mode
```

## Roles

### docker

Configures Docker to use the `overlay2` storage driver with optimized settings for OpenWrt.

**Tasks:**
- Deploys `dockerd-overlay2.sh` script
- Configures Docker daemon via UCI
- Sets up ext4 loopback filesystem or USB device for Docker storage
- Updates `/etc/rc.local` for persistent configuration

**Variables** (defined in `roles/docker/defaults/main.yml`):
- `docker_storage_driver`: Storage driver (default: `overlay2`)
- `docker_data_root`: Docker data directory (default: `/opt/docker`)
- `docker_image_path`: Path to ext4 image file (default: `/overlay/docker.ext4`)
- `docker_image_size_gb`: Size of ext4 image in GB (default: `20`)
- `docker_usb_device`: USB device path (default: `/dev/sda1`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

### gps

Configures GPS initialization for WM1302 Pi Hat with Quectel L76K GNSS module.

**Tasks:**
- Deploys `gps-init` script
- Enables GPS init script to run at boot
- Verifies GPS configuration

**Variables** (defined in `roles/gps/defaults/main.yml`):
- `gps_gpio_rst`: GPIO pin for GPS reset (default: `25`)
- `gps_gpio_wake`: GPIO pin for GPS wake control (default: `12`)
- `gps_tty_device`: TTY device for GPS (default: `/dev/ttyAMA0`)
- `gps_baud`: Baud rate (default: `9600`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

### atak

Deploys TAK Server scripts and configuration files.

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

Start OpenTAKServer (after deploying compose.yaml):

```bash
ansible openmanet_devices -m shell -a "cd ~/ots-docker && docker compose up -d"
```

## Troubleshooting

### Connection Issues

If you have SSH connection issues:

1. Test SSH connectivity manually:
   ```bash
   ssh root@192.168.1.1
   ```

2. Check inventory file for correct credentials

3. Use verbose mode to see connection details:
   ```bash
   ansible-playbook playbooks/site.yml -vvv
   ```

### Permission Issues

Ansible connects as the user specified in inventory (`ansible_user`). Make sure:
- The user has necessary permissions
- SSH keys are set up correctly if using key-based auth
- Password authentication is enabled if using passwords

### Task Failures

If a task fails:

1. Check the error message in the output
2. Run the playbook with `-vvv` for detailed debugging
3. Test the command manually on the device
4. Check that required files exist in role `files/` directories

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── hosts.yml           # Inventory file (create from example)
│   └── hosts.example.yml   # Example inventory
├── group_vars/
│   └── all.yml             # Global variables (optional overrides)
├── host_vars/              # Host-specific variables (optional)
│   └── gateway1.yml       # Example host-specific vars
├── playbooks/
│   ├── site.yml           # Main playbook (deploys everything)
│   ├── docker.yml         # Docker-only playbook
│   ├── gps.yml            # GPS-only playbook
│   ├── atak.yml           # TAK Server-only playbook
│   └── opentakserver.yml  # OpenTAKServer-only playbook
└── roles/
    ├── docker/
    │   ├── defaults/
    │   │   └── main.yml   # Docker role default variables
    │   ├── tasks/
    │   │   └── main.yml
    │   └── files/
    │       └── dockerd-overlay2.sh
    ├── gps/
    │   ├── defaults/
    │   │   └── main.yml   # GPS role default variables
    │   ├── tasks/
    │   │   └── main.yml
    │   └── templates/
    │       └── gps-init.j2
    ├── atak/
    │   ├── defaults/
    │   │   └── main.yml   # ATAK role default variables
    │   ├── tasks/
    │   │   └── main.yml
    │   └── files/
    │       ├── setup.sh
    │       ├── certDP.sh
    │       ├── shareCerts.sh
    │       └── docker-compose.arm.yml
    └── opentakserver/
        ├── defaults/
        │   └── main.yml   # OpenTAKServer role default variables
        ├── tasks/
        │   └── main.yml
        └── files/
            └── compose.yaml
```

## Migration from Bash Scripts

The Ansible playbooks replace the following bash scripts:

| Bash Script | Ansible Equivalent |
|------------|-------------------|
| `docker/deploy_dockerd_overlay2.sh` | `ansible-playbook playbooks/docker.yml` |
| `gps/deploy_gps_init.sh` | `ansible-playbook playbooks/gps.yml` |
| `atak/deploy_scripts.sh` | `ansible-playbook playbooks/atak.yml` |
| `opentakserver/deploy_compose.sh` | `ansible-playbook playbooks/opentakserver.yml` |

## Best Practices

1. **Use SSH Keys**: Instead of passwords, use SSH key authentication
2. **Use Ansible Vault**: Encrypt sensitive data with `ansible-vault`
3. **Test First**: Use `--check` mode before applying changes
4. **Version Control**: Keep inventory files in version control (excluding secrets)
5. **Idempotency**: All tasks are designed to be idempotent (safe to run multiple times)
6. **Backup**: Always backup before major changes

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [OpenMANET Documentation](https://openmanet.github.io/docs/)

