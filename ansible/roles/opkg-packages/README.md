# OPKG Packages Role

This role centralizes all `opkg update` and `opkg install` operations for OpenWrt systems.

## Purpose

This role consolidates package management operations that were previously scattered across multiple roles. It provides a single point of control for installing packages via OPKG.

## Variables

### `opkg_packages` (list, required)
List of packages to install. Default packages include:
- `git-http`
- `git`
- `openssh-client`
- `bash`
- `unzip`
- `coreutils-sha1sum`
- `htop`
- `ca-bundle`

### `opkg_packages_extra` (list, optional)
Additional packages to install beyond the default list. This allows roles to add specific packages without overriding the entire list.

Example:
```yaml
opkg_packages_extra:
  - curl
  - wget
```

### `opkg_update` (boolean, default: `true`)
Whether to run `opkg update` before installing packages.

## Usage

### In a playbook

```yaml
- hosts: openwrt_devices
  roles:
    - role: opkg-packages
      vars:
        opkg_packages_extra:
          - curl
          - wget
```

### In another role

```yaml
- name: Install required packages
  ansible.builtin.include_role:
    name: opkg-packages
```

Or with additional packages:

```yaml
- name: Install required packages
  ansible.builtin.include_role:
    name: opkg-packages
  vars:
    opkg_packages_extra:
      - curl
```

## Tags

- `opkg` - All tasks in this role
- `opkg-update` - Only the update task
- `opkg-install` - Only the install task

## Notes

- The install command uses `|| true` to prevent failures if a package is already installed or unavailable
- The install task uses `creates: /usr/bin/git` as an idempotency check (assuming git is in the package list)
