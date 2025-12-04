## Goal

Make docker work well on the openwrt gateway.

## Problem

docker info says we have  Storage Driver: vfs. We want overlay2

The `vfs` storage driver is inefficient and doesn't support copy-on-write, leading to:
- Slower container operations
- Higher disk space usage
- Poor performance

## Device

Connect to your OpenWrt device via SSH:
```bash
ssh root@<device-ip>
```

## Solution

### Current Working Setup (ext4 loopback + overlay2)

We ended up with Docker using **overlay2** backed by an **ext4 loopback file** because the root filesystem is `overlayfs`, which Docker cannot use directly as the `overlay2` upperdir.

**Key facts:**
- **Docker data-root**: `/opt/docker/`
- **Loopback image**: `/overlay/docker.ext4` (20 GB ext4 filesystem)
- **UCI config**: `/etc/config/dockerd` (Docker daemon configuration)
- **Generated config**: `/tmp/dockerd/daemon.json` (auto-generated from UCI by init script)
- **Result**: `docker info` shows `Storage Driver: overlay2`

**Configuration approach:** We use OpenWrt's UCI system (`/etc/config/dockerd`) to configure Docker. The dockerd init script automatically generates `/tmp/dockerd/daemon.json` from the UCI config. Since we only use simple options (no arrays or complex structures), UCI handles everything we need.

**One-shot commands we ran (DESTRUCTIVE – nukes all Docker data):**

```bash
# 1) Stop Docker and delete all old data
/etc/init.d/dockerd stop || true
rm -rf /opt/docker/*

# 2) Create a 20G ext4 loopback image under /overlay
SIZE_GB=20
IMG_PATH=/overlay/docker.ext4
MNT_DIR=/opt/docker

[ -f "$IMG_PATH" ] || dd if=/dev/zero of="$IMG_PATH" bs=1M count=0 seek=$((SIZE_GB*1024))
mkfs.ext4 -F "$IMG_PATH"
mkdir -p "$MNT_DIR"
mount -o loop "$IMG_PATH" "$MNT_DIR"

# 3) Configure Docker via UCI to use overlay2 + /opt/docker
uci set dockerd.globals.storage_driver="overlay2"
uci set dockerd.globals.data_root="/opt/docker/"
uci set dockerd.globals.log_level="debug"
uci set dockerd.globals.iptables="0"
uci set dockerd.globals.ip6tables="0"
uci commit dockerd

# 4) Start Docker and verify
/etc/init.d/dockerd start
sleep 3
docker info | grep "Storage Driver"
```

You should see:

```text
 Storage Driver: overlay2
```
---

### Making it persistent (rc.local + script)

We use `/etc/rc.local` to call a script that mounts the ext4 loopback on boot. This runs after the system init finishes, ensuring all filesystems are ready.

The mount setup uses a **bind mount** approach:
1. Mount the ext4 loopback image to `/mnt/docker-ext4`
2. Bind mount that to `/opt/docker` (overriding the overlayfs)

**Quick deployment:**

```bash
cd docker
# Option 1: Use .env file (recommended)
# From project root: cp .env.example .env
# Edit .env with your device IP and password
./deploy_dockerd_overlay2.sh

# Option 2: Provide credentials as arguments
./deploy_dockerd_overlay2.sh <device-ip> <device-password>
```

**Note**: The `.env` file in the project root is gitignored and will not be committed. Copy `.env.example` to `.env` in the project root and update it with your actual device credentials.

Or manually:

```bash
# 1) Copy the script to the device
scp docker/dockerd-overlay2.sh root@<device-ip>:/usr/bin/dockerd-overlay2.sh

# 2) Make it executable and update rc.local
ssh root@<device-ip>
chmod +x /usr/bin/dockerd-overlay2.sh

# 3) Update rc.local to call the script
cat > /etc/rc.local << 'EOF'
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

# Docker storage setup
/usr/bin/dockerd-overlay2.sh

exit 0
EOF
```

After a reboot, you should see:

```bash
mount | grep '/opt/docker'
# /dev/loop1 on /opt/docker type ext4 (rw,relatime)

docker info | grep "Storage Driver"
# Storage Driver: overlay2
```

---

### Manual Steps

If the script doesn't work, check:

1. **Kernel overlay support:**
   ```bash
   grep overlay /proc/filesystems
   ```
   If empty, install: `opkg update && opkg install kmod-fs-overlay`

2. **Load overlay module:**
   ```bash
   modprobe overlay
   ```

3. **Configure Docker daemon via UCI:**
   ```bash
   uci set dockerd.globals.storage_driver="overlay2"
   uci set dockerd.globals.data_root="/opt/docker/"
   uci set dockerd.globals.log_level="debug"
   uci set dockerd.globals.iptables="0"
   uci set dockerd.globals.ip6tables="0"
   uci commit dockerd
   ```

4. **Restart Docker** (see above)

### Troubleshooting

- If overlay filesystem is not supported, you may need to rebuild OpenWrt with overlay support
- Existing containers/images may need to be removed before switching storage drivers
- Check Docker logs: `logread | grep docker`