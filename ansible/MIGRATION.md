# Migration Guide: Bash Scripts to Ansible

This guide helps you migrate from the bash deployment scripts to Ansible.

## Overview

The Ansible setup replaces these bash scripts:

| Old Bash Script | New Ansible Command |
|----------------|---------------------|
| `docker/deploy_dockerd_overlay2.sh` | `ansible-playbook playbooks/docker.yml` |
| `gps/deploy_gps_init.sh` | `ansible-playbook playbooks/gps.yml` |
| `atak/deploy_scripts.sh` | `ansible-playbook playbooks/atak.yml` |
| `opentakserver/deploy_compose.sh` | `ansible-playbook playbooks/opentakserver.yml` |

## Key Differences

### Configuration

**Before (Bash):**
- Used `.env` file in project root
- Required `DEVICE_IP` and `DEVICE_PASS` variables
- Scripts read from `.env` or command-line arguments

**After (Ansible):**
- Uses `inventory/hosts.yml` for device information
- Supports multiple devices in one inventory
- Can use SSH keys instead of passwords
- Supports Ansible Vault for encrypted secrets

### Execution

**Before (Bash):**
```bash
cd docker
./deploy_dockerd_overlay2.sh 192.168.1.1 mypassword
```

**After (Ansible):**
```bash
cd ansible
ansible-playbook playbooks/docker.yml --limit gateway1
```

### Multi-Device Deployment

**Before (Bash):**
- Had to run scripts separately for each device
- Manual coordination required

**After (Ansible):**
- Deploy to all devices at once:
  ```bash
  ansible-playbook playbooks/site.yml
  ```
- Deploy to specific devices:
  ```bash
  ansible-playbook playbooks/site.yml --limit gateway1,gateway2
  ```

## Step-by-Step Migration

### 1. Install Ansible

See `README.md` for installation instructions.

### 2. Create Inventory

Convert your `.env` file to Ansible inventory:

**Old `.env` file:**
```bash
DEVICE_IP=192.168.1.1
DEVICE_USER=root
DEVICE_PASS=mypassword
```

**New `inventory/hosts.yml`:**
```yaml
all:
  children:
    openmanet_devices:
      hosts:
        gateway1:
          ansible_host: 192.168.1.1
          ansible_user: root
          ansible_password: mypassword
```

### 3. Test Connection

```bash
cd ansible
ansible openmanet_devices -m ping
```

### 4. Deploy Components

Replace your old script calls:

```bash
# Old way
cd docker && ./deploy_dockerd_overlay2.sh

# New way
ansible-playbook playbooks/docker.yml
```

## Feature Comparison

| Feature | Bash Scripts | Ansible |
|---------|--------------|---------|
| Single device | ✅ | ✅ |
| Multiple devices | ❌ | ✅ |
| Idempotent | ❌ | ✅ |
| Dry-run mode | ❌ | ✅ (`--check`) |
| Verbose output | Limited | ✅ (`-vvv`) |
| SSH keys | ❌ | ✅ |
| Encrypted secrets | ❌ | ✅ (Vault) |
| Rollback | ❌ | ✅ (with version control) |
| Parallel execution | ❌ | ✅ (by default) |

## Benefits of Ansible

1. **Idempotency**: Safe to run multiple times - won't break if already configured
2. **Multi-device**: Manage all devices from one place
3. **Better error handling**: Clear error messages and failure handling
4. **Dry-run**: Test changes before applying (`--check`)
5. **Modular**: Easy to customize and extend
6. **Version control**: Track changes to configurations
7. **Security**: Use SSH keys and Ansible Vault instead of plain passwords

## Keeping Both

You can keep both bash scripts and Ansible:
- Bash scripts remain in their original directories
- Ansible is in the `ansible/` directory
- Use whichever you prefer

## Troubleshooting Migration

### Issue: Connection fails

**Solution**: Check your inventory file matches the old `.env` values:
- `ansible_host` = old `DEVICE_IP`
- `ansible_user` = old `DEVICE_USER` (default: root)
- `ansible_password` = old `DEVICE_PASS`

### Issue: Permission denied

**Solution**: Make sure you're using the same user as before (usually `root`)

### Issue: Task fails

**Solution**: 
1. Run with verbose output: `ansible-playbook playbooks/site.yml -vvv`
2. Compare with old script output
3. Check that required files exist in role `files/` directories

## Next Steps

1. Read `QUICKSTART.md` for a quick start guide
2. Read `README.md` for detailed documentation
3. Customize role variables by overriding them in `group_vars/all.yml` or `host_vars/<hostname>.yml`
4. Consider using Ansible Vault for password management

