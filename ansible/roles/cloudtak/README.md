# cloudtak

Deploys CloudTAK, a TAK Compatible, browser-based Common Operation Picture & Situational Awareness tool, on the OpenMANET gateway using Docker Compose. CloudTAK is configured to work with HTTPS-enabled OpenTAKServer.

## Overview

This role clones the CloudTAK repository from GitHub, copies custom configuration files, builds Docker images, and starts the CloudTAK services. CloudTAK provides a web-based interface for TAK operations and includes ETL (Extract, Transform, Load) functionality for bringing non-TAK data sources into a TAK Server.

## Features

- Clones/updates CloudTAK repository from GitHub
- Deploys custom docker-compose.yml configuration
- Copies custom Dockerfiles and configuration files
- Creates .env file from .env.example if it doesn't exist
- Configures API_URL to point to CloudTAK's own HTTPS endpoint
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
cloudtak_cert_local_path: ~/.acme.sh/*.marmal.duckdns.org_ecc
```

**Note:** The role automatically creates a `.env` file from `.env.example` if it doesn't exist and sets `API_URL` to `https://cloudtak.marmal.duckdns.org:8440` to point to CloudTAK's own HTTPS endpoint. You can manually edit the `.env` file on the device after deployment to customize environment variables.

## Usage

### Deploy CloudTAK

Deploy CloudTAK:

```bash
ansible-playbook playbooks/site.yml --tags cloudtak
```

This will:

- Clone/update CloudTAK repository
- Deploy custom configuration files
- Update `API_URL` in `.env` to point to CloudTAK's HTTPS endpoint
- Build and start CloudTAK services

### Build and Start Services

Build and start CloudTAK services:

```bash
ansible-playbook playbooks/site.yml --tags cloudtak,cloudtak-build,cloudtak-start
```

### Restart Services

Restart CloudTAK services (useful after `.env` changes):

```bash
ansible-playbook playbooks/site.yml --tags cloudtak-start
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

CloudTAK services are accessible directly on the gateway:

- **Web UI**: `http://<gateway-ip>:5000` or `http://cloudtak.marmal.duckdns.org:5000`
- **Media API**: `http://<gateway-ip>:9997`
- **MinIO Console**: `http://<gateway-ip>:9002`
- **Tiles Server**: `http://<gateway-ip>:5002`

### CloudTAK API Configuration

CloudTAK's API_URL points to its own HTTPS endpoint:

- **API_URL**: `https://cloudtak.marmal.duckdns.org:8440`

This is automatically set in the `.env` file during deployment. CloudTAK's backend will communicate with OpenTAKServer for OAuth and file endpoints.

## Testing

After deployment, verify services are running:

```bash
# Check service status
cd ~/cloudtak
docker compose ps -a

# View logs
docker compose logs -f api

# Test CloudTAK access
curl http://localhost:5000

# Check API_URL is set correctly
grep API_URL ~/cloudtak/.env
```

### Verify OpenTAKServer Connection

Check that CloudTAK can reach OpenTAKServer:

```bash
# Test OTS API is accessible
curl -k https://ots.marmal.duckdns.org:8440/api

# Check CloudTAK logs for connection status
docker compose logs api | grep -i "ots\|api\|connection"
```

## Troubleshooting

### Services Fail to Start

1. Check Docker logs: `docker compose logs`
2. Verify disk space: `df -h`
3. Check Docker daemon: `docker ps`
4. Verify network connectivity: `ping github.com`
5. Check .env file: `cat ~/cloudtak/.env`

### Build Fails

1. Check Docker build logs: `docker compose build --no-cache`
2. Verify Dockerfile syntax
3. Check available disk space for images

### Repository Clone Fails

1. Verify GitHub access: `ping github.com`
2. Check SSH keys if using SSH URL
3. Verify git is installed: `which git`

### CloudTAK Can't Connect to OpenTAKServer

1. **Verify API_URL is set correctly**:

   ```bash
   grep API_URL ~/cloudtak/.env
   # Should show: API_URL=https://cloudtak.marmal.duckdns.org:8440
   ```

2. **Test OTS API accessibility**:

   ```bash
   curl -k https://ots.marmal.duckdns.org:8440/api
   ```

3. **Check CloudTAK logs for connection errors**:

   ```bash
   docker compose logs api | grep -i error
   ```

4. **Verify OTS nginx has CloudTAK locations**:
   - `/oauth` location should be in OTS certificate enrollment config (port 8446)
   - `/files` location should be in OTS HTTPS config (port 443/8440)

5. **Restart CloudTAK after .env changes**:

   ```bash
   cd ~/cloudtak
   docker compose restart api
   ```

## OpenTAKServer Integration

CloudTAK is configured to work with HTTPS-enabled OpenTAKServer. The following nginx locations must be configured in OpenTAKServer:

- **`/oauth` location**: Added to certificate enrollment server (port 8446)
- **`/files` location**: Added to HTTPS server (port 443/8440)

These are automatically configured when deploying OpenTAKServer with the `ots` tag.

## Notes

- Requires Docker and Docker Compose to be installed (handled by `docker` role)
- First deployment will take longer due to image builds
- Subsequent deployments will use cached images unless `--no-cache` is used
- The `.env` file is created from `.env.example` on first deployment
- `API_URL` is automatically set to `https://cloudtak.marmal.duckdns.org:8440` during deployment
- You can manually edit `.env` on the device to customize configuration (restart services after changes)
- Custom files in `files/` directory are copied after repository checkout
- CloudTAK is accessible directly on port 5000 (HTTP only, no HTTPS)

## References

- [CloudTAK Repository](https://github.com/dfpc-coe/CloudTAK)
- [CloudTAK Documentation](https://cloudtak.io/)
- [MediaMTX](https://github.com/bluenviron/mediamtx)
