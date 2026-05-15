# Plex Performance Optimization Guide

## Overview

This guide addresses common Plex performance issues including lag, playback failures, and slow loading times. Follow these optimizations to improve your Plex server performance.

## Common Issues and Solutions

### Issue 1: Video Lag/Stuttering

**Symptoms:**
- Video pauses frequently
- Audio/video sync issues
- Buffering interruptions

**Causes & Solutions:**

1. **Transcoding Overload**
   - **Solution**: Enable hardware acceleration
   - **Solution**: Pre-transcode media to avoid runtime transcoding
   - **Solution**: Use direct play/stream when possible

2. **Insufficient CPU/RAM**
   - **Solution**: Monitor resource usage during playback
   - **Solution**: Limit concurrent transcodes
   - **Solution**: Upgrade hardware if needed

3. **Network Bottleneck**
   - **Solution**: Use wired connection for server
   - **Solution**: Check network speed (run speedtest)
   - **Solution**: Verify QoS settings on router

4. **Slow Storage**
   - **Solution**: Use SSD for transcoding temporary directory
   - **Solution**: Optimize media storage (defragment if HDD)
   - **Solution**: Use faster storage for frequently accessed media

### Issue 2: Playback Failures

**Symptoms:**
- Videos fail to start
- Error messages during playback
- Connection timeouts

**Causes & Solutions:**

1. **Codec/Format Issues**
   - **Solution**: Transcode to compatible formats
   - **Solution**: Use universal codecs (H.264, AAC)
   - **Solution**: Check client compatibility

2. **File Corruption**
   - **Solution**: Verify file integrity
   - **Solution**: Re-download corrupted files
   - **Solution**: Check disk health

3. **Permission Issues**
   - **Solution**: Verify file permissions
   - **Solution**: Check Plex user permissions
   - **Solution**: Verify mount points are accessible

4. **Network Timeout**
   - **Solution**: Increase timeout settings
   - **Solution**: Check firewall rules
   - **Solution**: Verify port forwarding (if remote)

### Issue 3: Slow Loading/Scanning

**Symptoms:**
- Library scans take forever
   - Thumbnails slow to generate
   - Metadata slow to load

**Causes & Solutions:**

1. **Large Library**
   - **Solution**: Optimize library structure
   - **Solution**: Disable unnecessary metadata agents
   - **Solution**: Limit thumbnail generation (disable preview thumbnails)

2. **Database Issues**
   - **Solution**: Optimize database regularly
   - **Solution**: Check database file size
   - **Solution**: Rebuild database if corrupted

3. **Storage Performance**
   - **Solution**: Use SSD for Plex database/metadata
   - **Solution**: Optimize disk I/O
   - **Solution**: Use faster storage for library

## Configuration Optimizations

### Plex Settings

**Transcoder Settings:**
```
Settings > Transcoder

✓ Enable hardware acceleration (if supported)
- Transcoder quality: Automatic
- Transcoder temporary directory: /transcode (SSD if possible)
- Background transcoding x264 preset: veryfast (or faster)
- Transcoder default throttle buffer: 60 (increase for better buffering)
- Transcoder quality: Automatic
```

**Network Settings:**
```
Settings > Network

- Enable remote access: ✓
- Remote access port: 32400
- Preferred network interface: (select your main interface)
- Custom server access URLs: (leave blank unless needed)
- Enable IPv6: (enable if your network supports it)
```

**Library Settings:**
```
Settings > Library

- Generate video preview thumbnails: ✗ (disable for performance)
- Generate intro video markers: ✗ (disable if not needed)
- Generate chapter thumbnails: ✗ (disable for performance)
- Enable Cinema Trailers: ✗ (disable for performance)
```

**Performance Settings:**
```
Settings > Server

- Enable Plex Pass features: ✓ (if you have Plex Pass)
- Automatically adjust quality: ✓
- Home streaming quality: Maximum
```

### Docker Configuration

**Hardware Acceleration:**
```yaml
services:
  plex:
    devices:
      - /dev/dri:/dev/dri  # Intel Quick Sync / AMD
    environment:
      - NVIDIA_VISIBLE_DEVICES=all  # For NVIDIA GPUs
      - NVIDIA_DRIVER_CAPABILITIES=all
```

**Resource Limits:**
```yaml
services:
  plex:
    deploy:
      resources:
        limits:
          cpus: '4'  # Adjust based on your CPU
          memory: 8G  # Adjust based on your RAM
        reservations:
          cpus: '2'
          memory: 4G
```

**Transcoding Directory:**
```yaml
services:
  plex:
    volumes:
      - plex-transcode:/transcode  # Use tmpfs for better performance
    # Or use tmpfs:
    tmpfs:
      - /transcode:size=10G  # 10GB tmpfs for transcoding
```

**Network Optimization:**
```yaml
services:
  plex:
    network_mode: host  # Better performance, less NAT overhead
    # OR use custom network with proper MTU:
    networks:
      media:
        driver: bridge
        driver_opts:
          com.docker.network.driver.mtu: 1500
```

### System Optimizations

**Linux Network Tuning:**
```bash
# Increase network buffer sizes
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216'
sudo sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216'
sudo sysctl -w net.core.netdev_max_backlog=5000

# Make permanent
sudo nano /etc/sysctl.conf
# Add the above settings (without sudo sysctl -w)
```

**File System Optimization:**
```bash
# For ext4 filesystems
sudo tune2fs -o journal_data_writeback /dev/sda1
sudo mount -o remount,noatime /dev/sda1

# For better performance with media files
# Consider XFS for large media storage
```

**I/O Scheduler:**
```bash
# Set I/O scheduler to deadline or mq-deadline for SSDs
echo deadline | sudo tee /sys/block/sda/queue/scheduler

# Or use noop for SSDs
echo noop | sudo tee /sys/block/sda/queue/scheduler
```

**Priority/Nice Values:**
```bash
# Run Plex container with higher priority
# Add to docker-compose.yml:
services:
  plex:
    ulimits:
      rtprio: 99
      memlock: 1024000000
```

## Hardware Recommendations

### CPU
- **Minimum**: 4-core CPU (2000+ PassMark score)
- **Recommended**: 8-core CPU (8000+ PassMark score)
- **For Transcoding**: Intel with Quick Sync or NVIDIA GPU

### RAM
- **Minimum**: 4GB
- **Recommended**: 8-16GB
- **For Multiple Streams**: 16GB+

### Storage
- **OS/Database**: SSD (fast boot, quick database access)
- **Media Storage**: HDD (cost-effective for large libraries)
- **Transcoding**: SSD or tmpfs (fast temporary storage)

### Network
- **Server**: Gigabit Ethernet (wired)
- **Clients**: 5GHz WiFi or wired for best performance

## Monitoring Plex Performance

### Key Metrics to Monitor

1. **Active Streams**
   - Number of concurrent streams
   - Direct play vs transcoding ratio

2. **Transcoding Performance**
   - Transcode speed (should be >1.0x for smooth playback)
   - CPU usage during transcoding
   - Hardware acceleration usage

3. **Network Performance**
   - Bandwidth usage per stream
   - Network latency
   - Packet loss

4. **Resource Usage**
   - CPU usage (should stay <80% during playback)
   - Memory usage
   - Disk I/O

### Using Plex Dashboard

Access: `http://localhost:32400/web`

**Dashboard > Status:**
- Active streams
- Transcoding status
- Server performance

**Dashboard > Activities:**
- Current activities
- Transcoding details
- Bandwidth usage

### Prometheus Monitoring

**Plex Exporter** (if available):
```yaml
plex-exporter:
  image: mtoensing/plex-exporter:latest
  ports:
    - "9091:9091"
  environment:
    - PLEX_URL=http://plex:32400
    - PLEX_TOKEN=your-token
```

## Troubleshooting Steps

### Step 1: Check Current Performance

1. Access Plex dashboard
2. Start a problematic video
3. Check Dashboard > Activities
4. Note transcoding status, speed, and resource usage

### Step 2: Identify Bottleneck

**High CPU Usage:**
- Enable hardware acceleration
- Reduce concurrent transcodes
- Pre-transcode media

**High Memory Usage:**
- Increase available RAM
- Reduce transcoder buffer size
- Limit concurrent streams

**High Disk I/O:**
- Move transcoding to SSD/tmpfs
- Optimize storage
- Check for disk errors

**Network Issues:**
- Test network speed
- Check for congestion
- Verify QoS settings

### Step 3: Apply Fixes

1. Apply relevant optimizations from above
2. Restart Plex server
3. Test playback again
4. Monitor metrics

### Step 4: Verify Improvement

1. Check transcoding speed (should be >1.0x)
2. Monitor resource usage
3. Test with multiple clients
4. Verify stability over time

## Advanced Optimizations

### Pre-transcoding Media

**Using Plex:**
- Settings > Optimize
- Create optimized versions for common devices
- Use scheduled optimization

**Using HandBrake/FFmpeg:**
```bash
# Batch transcode to universal format
for file in *.mkv; do
    ffmpeg -i "$file" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a aac -b:a 192k \
        -movflags +faststart \
        "optimized/${file}"
done
```

### Library Optimization

1. **Organize Media Structure:**
   ```
   /media
   ├── movies/
   │   └── Movie Name (Year)/
   │       └── Movie Name (Year).mkv
   └── tv/
       └── Show Name/
           └── Season XX/
               └── Show Name - SXXEYY - Episode Name.mkv
   ```

2. **Naming Conventions:**
   - Follow Plex naming conventions
   - Use consistent formats
   - Include year for movies
   - Include season/episode for TV shows

3. **Metadata Management:**
   - Use correct metadata agents
   - Fix match errors
   - Clean up duplicate entries

### Database Maintenance

**Optimize Database:**
```bash
# Access Plex container
docker exec -it plex bash

# Optimize database (Plex does this automatically, but can be done manually)
# Database location: /config/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db
```

**Rebuild Database (if corrupted):**
1. Stop Plex
2. Backup database
3. Delete database (Plex will rebuild on next start)
4. Start Plex and let it rescan

## Quick Fix Checklist

- [ ] Enable hardware acceleration
- [ ] Move transcoding directory to SSD/tmpfs
- [ ] Optimize network settings
- [ ] Disable unnecessary features (preview thumbnails, etc.)
- [ ] Check and optimize storage
- [ ] Verify file permissions
- [ ] Test network connectivity
- [ ] Monitor resource usage
- [ ] Update Plex to latest version
- [ ] Check for disk errors
- [ ] Optimize database
- [ ] Review and optimize media formats

## Maintenance Schedule

**Daily:**
- Monitor active streams and performance

**Weekly:**
- Review Plex logs for errors
- Check disk space
- Verify backups

**Monthly:**
- Optimize database
- Review and clean up library
- Update Plex and system
- Review performance metrics

**Quarterly:**
- Full system performance review
- Hardware health check
- Network optimization review
- Storage optimization



