# Quick Start Guide

Get started with Ansible deployment in 5 minutes!

## Step 1: Install Ansible

**macOS:**
```bash
brew install ansible
```

**Linux:**
```bash
sudo apt-get install ansible
```

## Step 2: Configure Inventory

```bash
cd ansible
cp inventory/hosts.example.yml inventory/hosts.yml
```

Edit `inventory/hosts.yml` with your device IP and password:

```yaml
all:
  children:
    openmanet_devices:
      hosts:
        my_gateway:
          ansible_host: 192.168.1.1
          ansible_user: root
          ansible_password: your_password
```

## Step 3: Test Connection

```bash
ansible openmanet_devices -m ping
```

You should see:
```
my_gateway | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Step 4: Deploy!

Deploy everything:
```bash
ansible-playbook playbooks/site.yml
```

Or deploy specific components using tags:

```bash
# Just Docker
ansible-playbook playbooks/site.yml --tags docker

# Just GPS
ansible-playbook playbooks/site.yml --tags gps

# Just TAK Server
ansible-playbook playbooks/site.yml --tags atak

# Just OpenTAKServer
ansible-playbook playbooks/site.yml --tags ots
```

Or use the individual playbooks:

```bash
# Just Docker
ansible-playbook playbooks/docker.yml

# Just GPS
ansible-playbook playbooks/gps.yml

# Just TAK Server
ansible-playbook playbooks/atak.yml

# Just OpenTAKServer
ansible-playbook playbooks/opentakserver.yml
```

## That's It!

Your devices are now configured. See `README.md` for more advanced usage.

