# cloudtak

Deploys CloudTAK, a TAK Compatible, browser-based Common Operation Picture & Situational Awareness tool, on the OpenMANET gateway using Docker Compose.

## Overview

This role clones the CloudTAK repository from GitHub, copies custom configuration files, builds Docker images, and starts the CloudTAK services. CloudTAK provides a web-based interface for TAK operations and includes ETL (Extract, Transform, Load) functionality for bringing non-TAK data sources into a TAK Server.

## Features

- Clones/updates CloudTAK repository from GitHub
- Deploys custom docker-compose.yml configuration
- Copies custom Dockerfiles and configuration files
- Creates .env file from .env.example if it doesn't exist
- Builds Docker images using `docker compose build`
- Starts services using `docker compose up -d`

## Prerequisites

- Docker and Docker Compose installed on the gateway
- Network connectivity to GitHub
- Sufficient disk space for Docker images and repository

## Variables

Variables are defined in `defaults/main.yml`:

- `cloudtak_dir`: Directory where CloudTAK will be deployed (default: `~/cloudtak`)
- `cloudtak_version`: Git branch/tag to checkout (default: `main`)
- `compose_backup`: Whether to backup existing compose files (default: `true`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

### Example Configuration

```yaml
cloudtak_dir: /opt/cloudtak
cloudtak_version: v12.40.0
```

**Note:** The role automatically creates a `.env` file from `.env.example` if it doesn't exist. You can manually edit the `.env` file on the device after deployment to customize environment variables.

## Usage

Deploy CloudTAK:

```bash
ansible-playbook playbooks/site.yml --tags cloudtak
```

Build and start services:

```bash
ansible-playbook playbooks/site.yml --tags cloudtak,cloudtak-build,cloudtak-start
```

## Services

CloudTAK deploys the following Docker services:

- **api**: Main CloudTAK API service (port 5000)
- **tiles**: PMTiles tile server (port 5002)
- **events**: Event processing service (port 5003)
- **media**: MediaMTX media server (ports 9997, 8554, 1935, 8888, 8890, 8889)
- **postgis**: PostgreSQL with PostGIS extension (port 5433)
- **store**: MinIO object storage (ports 9000, 9002)

## Custom Files

The role deploys custom files from `files/` directory:

- `docker-compose.yml`: Main Docker Compose configuration
- `media/mediamtx.yml`: MediaMTX configuration
- `tasks/pmtiles/Dockerfile.compose`: PMTiles service Dockerfile

These files override the default files from the CloudTAK repository.

## Network Configuration

By default, CloudTAK services are accessible on the mesh network (10.41.0.0/16). The API is available at:

- Web UI: `http://<gateway-ip>:5000`
- Media API: `http://<gateway-ip>:9997`
- MinIO Console: `http://<gateway-ip>:9002`

## Testing

After deployment, verify services are running:

```bash
# Check service status
docker compose ps -a

# View logs
docker compose logs -f api

# Access web UI
curl http://localhost:5000
```

## Troubleshooting

If services fail to start:

1. Check Docker logs: `docker compose logs`
2. Verify disk space: `df -h`
3. Check Docker daemon: `docker ps`
4. Verify network connectivity: `ping github.com`
5. Check .env file: `cat ~/cloudtak/.env`

If build fails:

1. Check Docker build logs: `docker compose build --no-cache`
2. Verify Dockerfile syntax
3. Check available disk space for images

If repository clone fails:

1. Verify GitHub access: `ping github.com`
2. Check SSH keys if using SSH URL
3. Verify git is installed: `which git`

## Notes

- Requires Docker and Docker Compose to be installed (handled by `docker` role)
- First deployment will take longer due to image builds
- Subsequent deployments will use cached images unless `--no-cache` is used
- The `.env` file is created from `.env.example` on first deployment
- You can manually edit `.env` on the device to customize configuration
- Custom files in `files/` directory are copied after repository checkout

## References

- CloudTAK Repository: https://github.com/dfpc-coe/CloudTAK
- CloudTAK Documentation: https://cloudtak.io/
- MediaMTX: https://github.com/bluenviron/mediamtx

