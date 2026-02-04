# Docker Path Compatibility Guide

**Purpose**: Understanding how fstab changes affect Docker service paths

---

## 📋 Current Docker Volume Mappings

### STARR Stack Services

**Radarr:**
```yaml
volumes:
  - /usr/local/bin/radarr/config:/config
  - /data:/data
  - /data/media/Movies:/Movies
  - /data/media/downloads:/downloads
  - /external/media:/external
  - /data/synology:/synology
```

**Sonarr:**
```yaml
volumes:
  - /usr/local/bin/sonarr/config:/config
  - /data:/data
  - /data/media/TV Shows:/TV Shows
  - /data/media/downloads:/downloads
  - /external/media:/external
  - /data/synology:/synology
```

**qBittorrent:**
```yaml
volumes:
  - /usr/local/bin/qbittorrent/config:/config
  - /data/media/downloads:/downloads
  - /external/media/torrents:/data/torrents
  - /external/media:/external
```

### Plex

```yaml
volumes:
  - /app/plex/config:/config
  - /external:/external
  - /home/youruser/synology/Media:/nas
```

---

## 🔄 fstab Changes Impact

### Recommended Approach: **Keep Current Paths (No Docker Changes)**

The optimized fstab maintains compatibility with your existing Docker configurations by using bind mounts and symlinks.

**Optimized fstab Structure:**
```
/mnt/synology (primary CIFS mount)
  └─ Bind mount → /data/media (for Docker)
  └─ Bind mount → /home/youruser/synology (for Plex)
```

**Result:** ✅ No Docker compose file changes needed

---

## 📊 Path Mapping After fstab Update

### Path Resolution

| Docker Path | Host Path (After fstab) | Notes |
|-------------|-------------------------|-------|
| `/data/media` | `/data/media` | Bind mount from `/mnt/synology/Media` |
| `/external/media` | `/external/media` | Direct NTFS mount (unchanged) |
| `/data/synology` | `/data/synology` | Symlink to `/mnt/synology` or bind mount |
| `/nas` (Plex) | `/home/youruser/synology/Media` | Bind mount from `/mnt/synology/Media` |

### How It Works

1. **Primary Mount**: `//192.168.1.20/Hulk` → `/mnt/synology` (CIFS)
2. **Bind Mounts**:
   - `/mnt/synology/Media` → `/data/media` (for STARR stack)
   - `/mnt/synology` → `/home/youruser/synology` (for Plex)
3. **Symlink** (if needed):
   - `/data/synology` → `/mnt/synology` (symbolic link)

**Benefits:**
- ✅ Single CIFS mount (eliminates duplicates)
- ✅ Docker paths unchanged (no service updates)
- ✅ Consistent mount options (fixes CIFS errors)
- ✅ Better performance (optimized options)

---

## 🔧 If You Want to Consolidate Paths

### Option: Use `/mnt/synology` as Single Base

**Requires Docker Compose Updates:**

**Updated Radarr/Sonarr:**
```yaml
volumes:
  - /usr/local/bin/radarr/config:/config
  - /mnt/synology:/data  # Instead of /data
  - /mnt/synology/Media/Movies:/Movies
  - /mnt/synology/Media/downloads:/downloads
  - /external/media:/external
  - /mnt/synology:/synology
```

**Updated Plex:**
```yaml
volumes:
  - /app/plex/config:/config
  - /external:/external
  - /mnt/synology/Media:/nas  # Instead of /home/youruser/synology/Media
```

**Pros:**
- Cleaner structure
- Single mount point
- Easier to understand

**Cons:**
- Requires updating all Docker compose files
- Need to restart all services
- More risk of errors

**Recommendation:** Keep current paths using bind mounts (easier, safer)

---

## ✅ Verification Steps

After updating fstab:

```bash
# 1. Verify mounts
mount | grep -E 'synology|cifs|bind'

# 2. Check paths accessible
ls -la /mnt/synology
ls -la /data/media
ls -la /home/youruser/synology

# 3. Test Docker access
docker exec radarr ls -la /data/media
docker exec sonarr ls -la /data/media
docker exec plex ls -la /nas

# 4. Verify file operations
docker exec radarr touch /data/media/test.txt && rm /data/media/test.txt
docker exec plex touch /nas/test.txt && rm /nas/test.txt

# 5. Check no errors
dmesg | grep -i cifs | tail -20
```

---

## 📝 Summary

**Recommended Approach:**
- ✅ Use optimized fstab with bind mounts
- ✅ Keep existing Docker paths
- ✅ No Docker compose changes needed
- ✅ Fixes CIFS errors
- ✅ Improves performance

**Result:** All Docker services continue working with improved reliability and performance.

