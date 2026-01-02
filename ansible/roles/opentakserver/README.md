# opentakserver

Deploys OpenTAKServer Docker Compose configuration. Based on https://github.com/milsimdk/ots-docker

## Tasks

- Creates OpenTAKServer directory
- Backs up existing `compose.yaml` if present
- Copies `compose.yaml` configuration
- Deploys nginx configuration templates
- Deploys SSL certificates (optional, with `ots-certs` tag)
- Verifies deployment

## Variables

Variables are defined in `defaults/main.yml`:

- `opentakserver_dir`: OpenTAKServer directory (default: `~/ots-docker`)
- `compose_backup`: Whether to backup existing compose.yaml (default: `true`)
- `ots_cert_local_path`: Local path to certificates on Ansible control machine (default: `~/.acme.sh/*.marmal.duckdns.org_ecc`)
- `ots_cert_fullchain`: Full chain certificate filename (default: `fullchain.cer`)
- `ots_cert_key`: Private key filename pattern (default: `*.marmal.duckdns.org.key`)
- `ots_cert_ca`: CA certificate filename (default: `ca.cer`)
- `ots_cert_remote_path`: Remote path where certificates are stored (default: `persistent/ots/ca`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

## Usage

Deploy OpenTAKServer:
```bash
ansible-playbook playbooks/site.yml --tags ots
```

Deploy SSL certificates (can be run independently):
```bash
ansible-playbook playbooks/site.yml --tags ots-certs
```

Deploy OpenTAKServer with SSL certificates:
```bash
ansible-playbook playbooks/site.yml --tags ots,ots-certs
```

Start services:
```bash
ansible-playbook playbooks/site.yml --tags ots,ots-start
```

## SSL Certificate Deployment

The role supports deploying SSL certificates from your local machine to the gateway node. Certificates are:

1. **Copied from local machine**: Certificates are read from the path specified in `ots_cert_local_path` (default: `~/.acme.sh/*.marmal.duckdns.org_ecc`)
2. **Deployed to remote host**: Certificates are copied to `{{ opentakserver_dir }}/{{ ots_cert_remote_path }}` (default: `~/ots-docker/persistent/ots/ca`)
3. **Used by nginx**: The nginx certificate include file is deployed to `persistent/nginx/templates/includes.d/opentakserver_certificate`
4. **Mounted in container**: Certificates are mounted read-only into the nginx container at `/app/ots/ca`

### Certificate Files

The role expects the following certificate files:
- `fullchain.cer` - Full certificate chain (includes intermediate certificates)
- `*.marmal.duckdns.org.key` - Private key (will be renamed to `privkey.key` on remote host)
- `ca.cer` - CA certificate (optional)

### Security

- Certificate files are **never committed to git** (excluded via `.gitignore`)
- Private keys are deployed with `0600` permissions (owner read/write only)
- Certificate files are deployed with `0644` permissions
- Certificates are mounted read-only in the Docker container

### Custom Certificate Paths

To use certificates from a different location, override the variables:

```yaml
# In group_vars/all.yml or host_vars/gateway.yml
ots_cert_local_path: /path/to/your/certificates
ots_cert_fullchain: fullchain.pem
ots_cert_key: "*.example.com.key"
```

## Notes

- After deployment, you need to run `docker compose up -d` on the device (or use the `ots-start` tag)
- The nginx certificate include file is based on the configuration from [milsimdk/ots-docker](https://github.com/milsimdk/ots-docker)
- Certificate deployment can be run independently with just the `ots-certs` tag, or combined with `ots` tag for full deployment
