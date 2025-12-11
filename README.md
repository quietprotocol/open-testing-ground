# Open Testing Ground

This repository contains setup scripts and documentation for configuring OpenMANET gateways running OpenWrt with Docker, GPS, and TAK Server support.

**DISCLAIMER! THIS PROJECT IS NOT ASSOCIATED WITH OPENMANET. IT'S MERELY A SANDBOX FOR TESTING POSSIBILITIES THIS IS CLANKER TERRITORY. USE AT YOUR OWN RISK. NO REFUNDS.**

## Overview

This repository provides two deployment approaches:

1. **Ansible** (Recommended) - Modern, idempotent deployment with multi-device management
2. **Bash Scripts** - Legacy deployment scripts for individual device setup

## Documentation

### Ansible Deployment

For Ansible-based deployment, see: **[`ansible/README.md`](ansible/README.md)**

The Ansible setup provides:
- Idempotent deployments (safe to run multiple times)
- Multi-device management via inventory
- Modular roles for each component
- Better error handling and logging
- Dry-run capability with `--check`

**Quick Start:**
```bash
cd ansible
cp inventory/hosts.example.yml inventory/hosts.yml
# Edit inventory/hosts.yml with your device info
ansible-playbook playbooks/site.yml
```

### Bash Scripts Deployment

For bash script-based deployment, see: **[`bash/README.md`](bash/README.md)**

The bash scripts provide:
- Simple, script-based deployment
- Individual device configuration
- Step-by-step setup process
- Environment variable support

## Getting Started

1. **Choose your deployment method:**
   - For managing multiple devices: Use [Ansible](ansible/README.md)
   - For single device setup: Use [Bash Scripts](bash/README.md)

2. **Follow the documentation:**
   - Read the appropriate README for your chosen method
   - Follow the setup instructions step by step

## References

- [OpenMANET OpenWrt Repository](https://github.com/OpenMANET/openwrt)
- [OpenMANET Documentation](https://openmanet.github.io/docs/)
- [TAK Product Center](https://tak.gov)
- [Cloud-RF TAK Server](https://github.com/Cloud-RF/tak-server)
- [OpenTAKServer](https://github.com/brian7704/OpenTAKServer) - Open-source TAK Server alternative

