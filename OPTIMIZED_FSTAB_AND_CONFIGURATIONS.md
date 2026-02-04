# Optimized fstab & Service Configuration

**Date**: 2025-12-29
**Server**: mediaserver (192.168.1.11)
**Purpose**: Corrected fstab with proper CIFS mounts and Docker-compatible paths

---

## 📋 Corrected /etc/fstab Configuration

### Complete Optimized fstab

```bash
# /etc/fstab: static file system information
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

# Root filesystem
UUID=32c69231-728d-11e8-84f5-74d02b912ea0 / ext4 defaults,noatime,errors=remount-ro 0 1

# Boot EFI partition
UUID=A744-1EF1 /boot/efi vfat defaults,umask=0077 0 2

# Swap
/swap.img none swap sw 0 0

# External NTFS Drive (2TB)
UUID=AC8C2E998C2E5DD8 /external/media ntfs defaults,uid=1000,gid=1004,umask=0022,noatime,noauto 0 2

# Synology NAS - Primary Mount (Auto-mount on access)
# This mount provides access to entire NAS share
//192.168.1.20/Hulk /mnt/synology cifs \
  credentials=/etc/samba/credentials,\
  vers=3.11,\
  noserverino,\
  soft,\
  noatime,\
  nofail,\
  timeo=600,\
  retrans=3,\
  rsize=1048576,\
  wsize=1048576,\
  cache=strict,\
  uid=1000,\
  gid=1004,\
  file_mode=0755,\
  dir_mode=0755,\
  x-systemd.automount,\
  x-systemd.idle-timeout=300 \
  0 0

# Bind mounts for compatibility (using /mnt/synology as base)
# These create symlink-like functionality without actual symlinks
/mnt/synology/Media /data/media none bind,noauto 0 0
/mnt/synology /home/youruser/synology none bind,noauto 0 0
```

### Alternative: Keep Current Paths (Recommended for Compatibility)

**If you want to keep existing paths without changing Docker configurations:**

```bash
# /etc/fstab: static file system information
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

# Root filesystem
UUID=32c69231-728d-11e8-84f5-74d02b912ea0 / ext4 defaults,noatime,errors=remount-ro 0 1

# Boot EFI partition
UUID=A744-1EF1 /boot/efi vfat defaults,umask=0077 0 2

# Swap
/swap.img none swap sw 0 0

# External NTFS Drive (2TB) - Only mount when needed
UUID=AC8C2E998C2E5DD8 /external/media ntfs defaults,uid=1000,gid=1004,umask=0022,noatime 0 2

# Synology NAS - Main share (auto-mount on access)
//192.168.1.20/Hulk /mnt/synology cifs \
  credentials=/etc/samba/credentials,\
  vers=3.11,\
  noserverino,\
  soft,\
  noatime,\
  nofail,\
  timeo=600,\
  retrans=3,\
  rsize=1048576,\
  wsize=1048576,\
  cache=strict,\
  uid=1000,\
  gid=1004,\
  file_mode=0755,\
  dir_mode=0755,\
  x-systemd.automount,\
  x-systemd.idle-timeout=300 \
  0 0

# Direct Media mount for /data/media (for Docker services)
/mnt/synology/Media /data/media none bind 0 0

# Symlink for /home/youruser/synology (compatibility)
# Note: Create as actual symlink, not bind mount
# ln -s /mnt/synology /home/youruser/synology
```

---

## 🔐 Credentials File Setup

### Create Secure Credentials File

```bash
# Create credentials file
sudo mkdir -p /etc/samba
sudo tee /etc/samba/credentials > /dev/null <<EOF
username=SCAdmin
password=YOUR_SYNO_PASSWORD_HERE
domain=
EOF

# Secure permissions
sudo chmod 600 /etc/samba/credentials
sudo chown root:root /etc/samba/credentials
```

---

## 📊 Mount Option Explanations

### Key Optimizations

| Option | Purpose | Why |
|--------|---------|-----|
| `vers=3.11` | SMB 3.1.1 protocol | Better performance, security, modern |
| `noserverino` | Disable server inode numbers | **Fixes CIFS errors** - Synology doesn't support properly |
| `soft` | Don't hang on errors | Prevents system hangs if NAS disconnects |
| `noatime` | Don't update access times | **Performance boost** - Reduces disk writes |
| `nofail` | Don't fail boot if mount fails | Prevents boot issues if NAS is down |
| `timeo=600` | 10 minute timeout | Longer timeout for network operations |
| `retrans=3` | Retry 3 times | Better reliability on transient network issues |
| `rsize/wsize=1048576` | 1MB buffer size | **Optimized for large file transfers** |
| `cache=strict` | Aggressive caching | Better performance for media files |
| `x-systemd.automount` | Mount on access | **Lazy mount** - Only mounts when accessed |
| `x-systemd.idle-timeout=300` | Auto-unmount after 5min idle | Saves resources, remounts automatically |

---

## 🔄 Migration Steps

### Step 1: Backup Current Configuration

```bash
# Backup fstab
sudo cp /etc/fstab /etc/fstab.backup-$(date +%Y%m%d_%H%M%S)

# Backup credentials (if exists)
sudo cp /home/youruser/.smbcredentials /home/youruser/.smbcredentials.backup 2>/dev/null || true
```

### Step 2: Create Credentials File

```bash
# Extract password from old credentials (if exists)
OLD_PASS=$(cat /home/youruser/.smbcredentials 2>/dev/null | grep password= | cut -d= -f2)

# Create new credentials file
sudo mkdir -p /etc/samba
sudo tee /etc/samba/credentials > /dev/null <<EOF
username=SCAdmin
password=${OLD_PASS:-YOUR_PASSWORD_HERE}
domain=
EOF

sudo chmod 600 /etc/samba/credentials
sudo chown root:root /etc/samba/credentials
```

### Step 3: Create Mount Points

```bash
# Create primary mount point
sudo mkdir -p /mnt/synology

# Ensure /data/media exists
sudo mkdir -p /data/media
sudo chown 1000:1004 /data/media
sudo chmod 755 /data/media

# Create /home/youruser/synology if doesn't exist
mkdir -p /home/youruser/synology

# If /data/synology doesn't exist, create it
sudo mkdir -p /data/synology
sudo chown 1000:1004 /data/synology
```

### Step 4: Update fstab

```bash
# Edit fstab
sudo nano /etc/fstab

# Use the optimized configuration above
```

### Step 5: Unmount Old Mounts

```bash
# Stop Docker services that use these mounts
cd /home/youruser/Docker/config/data_gluetun
docker-compose down

# Also stop Plex if needed
docker stop plex

# Unmount existing mounts
sudo umount /data/media 2>/dev/null || true
sudo umount /home/youruser/synology 2>/dev/null || true

# If automount, disable it temporarily
sudo systemctl stop home-youruser-synology.automount 2>/dev/null || true
```

### Step 6: Test New Configuration

```bash
# Test fstab syntax
sudo mount -a

# Verify mounts
mount | grep -E 'synology|cifs'

# Test automount
ls /mnt/synology
ls /data/media

# Check for errors
dmesg | grep -i cifs | tail -20
journalctl -k | grep -i cifs | tail -20
```

### Step 7: Update /data/synology (If Used)

```bash
# Check what /data/synology is
ls -la /data/synology

# If it's a directory, it should be accessible via /mnt/synology
# Create symlink if needed:
sudo ln -sfn /mnt/synology /data/synology

# Or if Docker needs specific path, update Docker compose files
```

### Step 8: Restart Services

```bash
# Restart Docker services
cd /home/youruser/Docker/config/data_gluetun
docker-compose up -d

docker start plex

# Verify all services can access mounts
docker exec radarr ls -la /data/media
docker exec sonarr ls -la /data/media
docker exec plex ls -la /nas
```

---

## 🔍 Docker Path Compatibility

### Current Docker Volume Mappings

**STARR Stack Services:**
- Radarr/Sonarr:
  - `/data` → Host `/data`
  - `/data/media/Movies` → Host `/data/media/Movies`
  - `/data/media/TV Shows` → Host `/data/media/TV Shows`
  - `/data/media/downloads` → Host `/data/media/downloads`
  - `/external/media` → Host `/external/media`
  - `/data/synology` → Host `/data/synology` (or `/home/youruser/synology`)

- qBittorrent:
  - `/downloads` → Host `/data/media/downloads`
  - `/external/media/torrents` → Host `/external/media/torrents`
  - `/external/media` → Host `/external/media`

**Plex:**
- `/nas` → Host `/home/youruser/synology/Media` (or `/data/media`)
- `/external` → Host `/external`

### After fstab Update - Path Compatibility

**Option 1: Keep All Current Paths (Recommended)**
- ✅ No Docker changes needed
- ✅ Use bind mounts to maintain paths
- ✅ Symlinks where needed

**Option 2: Consolidate to Single Base Mount**
- ⚠️ Requires Docker compose updates
- ✅ Cleaner structure
- ✅ Single source of truth

---

## 📝 Docker Compose Path Updates (If Consolidating)

If you want to consolidate to use `/mnt/synology` as the single mount:

### Updated Volume Mappings

```yaml
# STARR Stack (example for Radarr/Sonarr)
volumes:
  - /usr/local/bin/radarr/config:/config
  - /mnt/synology/Media:/data/media
  - /mnt/synology:/data/synology
  - /external/media:/external
  - /mnt/synology/Media/downloads:/downloads

# Plex
volumes:
  - /app/plex/config:/config
  - /mnt/synology/Media:/nas
  - /external:/external
```

**Note**: This requires updating all Docker compose files. **Option 1 (keeping current paths) is recommended** to avoid breaking changes.

---

## ✅ Verification Checklist

After updating fstab:

- [ ] fstab syntax valid: `sudo mount -a` succeeds
- [ ] Credentials file created and secured
- [ ] Mounts accessible: `ls /mnt/synology` works
- [ ] Bind mounts working: `ls /data/media` works
- [ ] No CIFS errors: `dmesg | grep -i cifs` shows no errors
- [ ] Docker services can access paths
- [ ] Plex can access media: `docker exec plex ls /nas`
- [ ] STARR services can access paths: `docker exec radarr ls /data/media`
- [ ] Performance acceptable: Test file operations

---

## 🔧 Troubleshooting

### Mount Fails at Boot

```bash
# Check fstab syntax
sudo mount -a

# Check credentials
sudo cat /etc/samba/credentials

# Test manual mount
sudo mount -t cifs //192.168.1.20/Hulk /mnt/test -o credentials=/etc/samba/credentials,vers=3.11

# Check NAS connectivity
ping -c 3 192.168.1.20
smbclient -L //192.168.1.20 -U SCAdmin
```

### Docker Services Can't Access Paths

```bash
# Check mount points exist and are accessible
ls -la /data/media
ls -la /mnt/synology

# Check permissions
stat /data/media
stat /mnt/synology

# Verify Docker can see mounts
docker exec radarr ls -la /data/media
```

### Still Getting CIFS Errors

```bash
# Ensure noserverino is in mount options
mount | grep cifs

# Check for old mounts
mount | grep -E 'synology|cifs'

# Unmount all and remount
sudo umount -a -t cifs
sudo mount -a
```

---

**Next Steps**: See service optimization recommendations in companion documents.

