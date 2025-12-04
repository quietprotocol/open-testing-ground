# OpenTAKServer for OpenWrt

This directory contains the Docker Compose configuration for [OpenTAKServer (OTS)](https://github.com/brian7704/OpenTAKServer), an open-source TAK Server alternative for ATAK, iTAK, and WinTAK clients.

## Origin

This setup is based on the [milsimdk/ots-docker](https://github.com/milsimdk/ots-docker) Docker Compose configuration, modified to work with OpenWrt devices that have port conflicts with the default configuration.

## Port Conflicts and Changes

OpenWrt devices typically run `uhttpd` (LuCI web interface) on ports 80 and 443, and may have other services using common ports. This configuration uses alternative ports to avoid conflicts:

### Port Mappings

| Service | Original Port | Modified Port | Description |
|---------|--------------|---------------|-------------|
| HTTP Web UI | 80 | **8880** | Web interface (HTTP) |
| HTTPS Web UI | 443 | **8440** | Web interface (HTTPS) |
| HTTP API | 8080 | **8881** | API requests to OpenTAKServer |
| HTTPS API | 8443 | **8443** | API requests to OpenTAKServer (unchanged) |
| Certificate Enrollment | 8446 | **8446** | Certificate enrollment proxy (unchanged) |
| MQTT/Meshtastic | 8883 | **8883** | MQTT proxy to RabbitMQ (unchanged) |
| TCP CoT Stream | 8088 | **8088** | CoT streaming (unchanged) |
| SSL CoT Stream | 8089 | **8089** | SSL CoT streaming (unchanged) |

### Common OpenWrt Port Conflicts

- **Port 80**: Used by `uhttpd` (LuCI web interface)
- **Port 443**: Used by `uhttpd` (LuCI HTTPS)
- **Port 8080**: May be used by `uhttpd` for other services (e.g., dump1090)

## Prerequisites

### OpenWrt Device Requirements

- OpenWrt device with Docker support
- At least 4GB RAM recommended (8GB+ for better performance)
- Sufficient storage for Docker images and persistent data (~2GB+)
- Network interface configured and accessible

### Docker Setup

Before installing OpenTAKServer, ensure Docker is properly configured on OpenWrt:

1. **Docker Storage Configuration**: Use the optimized Docker storage setup script:

   ```bash
   # Deploy the dockerd-overlay2.sh script
   cd ../docker
   ./deploy_dockerd_overlay2.sh
   ```

   This script:
   - Configures Docker to use `overlay2` storage driver
   - Optimizes for OpenWrt's filesystem (USB storage preferred, loopback fallback)
   - Disables bridge netfilter to allow Docker inter-container communication

2. **Verify Docker is running**:

   ```bash
   docker ps
   ```

## Installation

### Step 1: Clone ots-docker Repository

On your OpenWrt device, clone the ots-docker repository:

```bash
cd ~
git clone https://github.com/milsimdk/ots-docker.git
cd ots-docker
```

### Step 2: Deploy Modified Compose File

From your development machine, deploy the modified `compose.yaml`:

```bash
# From your development machine
cd /path/to/OpenMANET-testing-ground/opentakserver
./deploy_compose.sh [openwrt-ip]
```

Or manually copy the file:

```bash
scp compose.yaml root@<device-ip>:~/ots-docker/
```

### Step 3: Start OpenTAKServer

On the OpenWrt device:

```bash
cd ~/ots-docker
make up
```

Or using docker compose directly:

```bash
cd ~/ots-docker
docker compose -f compose.yaml up -d
```

### Step 4: Check Logs

Monitor the startup process:

```bash
cd ~/ots-docker
make logs
```

Or:

```bash
docker compose -f compose.yaml logs -f
```

## Accessing the Web UI

After the containers are running, access the Web UI at:

- **HTTP**: `http://<device-ip>:8880`
- **HTTPS**: `https://<device-ip>:8440`

**Note**: You may need to accept self-signed certificates or import CA certificates for HTTPS access.

## Port Usage Summary

The following ports are used by OpenTAKServer:

- **8880** - HTTP Web UI
- **8440** - HTTPS Web UI
- **8881** - HTTP API
- **8443** - HTTPS API
- **8446** - Certificate enrollment
- **8883** - MQTT/Meshtastic proxy
- **8088** - TCP CoT streaming
- **8089** - SSL CoT streaming

## Container Management

**Start containers:**
```bash
cd ~/ots-docker
make up
```

**Stop containers:**
```bash
cd ~/ots-docker
make down
```

**View logs:**
```bash
cd ~/ots-docker
make logs
```

**Restart containers:**
```bash
cd ~/ots-docker
make restart
```

## Troubleshooting

### Port Already in Use

If you get port binding errors, check what's using the port:

```bash
netstat -tlnp | grep :<port>
lsof -i :<port>
```

Common conflicts:
- Port 80/443: `uhttpd` (LuCI)
- Port 8080: Other `uhttpd` instances (e.g., dump1090)

### Container Won't Start

Check container logs:

```bash
docker compose -f compose.yaml logs <service-name>
```

Common services:
- `ots` - Main OpenTAKServer
- `nginx-proxy` - Nginx reverse proxy
- `ots-db` - PostgreSQL database
- `rabbitmq` - RabbitMQ message broker

### Database Connection Issues

If the database container isn't healthy:

```bash
docker compose -f compose.yaml logs ots-db
docker compose -f compose.yaml ps ots-db
```

### Slow Startup

OpenTAKServer may take several minutes to fully start on OpenWrt devices due to:
- Limited CPU resources
- Filesystem I/O overhead
- Service initialization time

Be patient and monitor logs for "healthy" status.

## Configuration

Configuration files are stored in `persistent/ots/config.yml`. You can modify settings there and restart the containers.

Environment variables can be set in `compose.override.yaml` (create from `compose.override.yaml-example`). Variables must have the `DOCKER_` prefix to be recognized.

## References

- [OpenTAKServer](https://github.com/brian7704/OpenTAKServer) - Main OpenTAKServer project
- [ots-docker](https://github.com/milsimdk/ots-docker) - Original Docker Compose setup
- [TAK Product Center](https://tak.gov) - Official TAK documentation

## License

This configuration is based on ots-docker which is licensed under GPL-3.0. See the original repository for license details.

