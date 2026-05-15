# Media Corruption Scanning - Quick Reference

**Last Updated**: January 9, 2026
**For complete documentation**: See [media-corruption-scanning.md](media-corruption-scanning.md)

---

## Quick Start

### Run Adaptive Scan (Recommended)

```bash
# Start scan in screen session with persistent storage
./scripts/run_adaptive_scan_persistent.sh

# Check status
./scripts/check_adaptive_scan_status.sh

# Re-attach to screen
screen -r adaptive_scan
```

### Quarantine Corrupted Files

```bash
# After scan completes, quarantine CORRUPT files
RESULTS=/home/youruser/stable_scan/results/adaptive_scan_*_phase2_fulldecode.txt \
./scripts/quarantine_corrupt_media.sh
```

---

## Configuration

### Worker Settings

**4-core system** (recommended):
- Phase 1: 8 workers
- Phase 2: 8 workers

**Higher-end system**:
- Phase 1: 12 workers
- Phase 2: 12 workers

**Adjust if system overloaded**:
- Monitor load average (should stay below cores × 3)
- Reduce workers if containers become unhealthy

### Scan Parameters

**Phase 1 (Sampling)**:
- PARTS: 20 (sampling points)
- SLICE: 10 (seconds per sample)
- TIMEOUT: 120 seconds per sample

**Phase 2 (Full-Decode)**:
- TIMEOUT: 1800 seconds (30 minutes) per file
- Slow-lane: 7200 seconds (2 hours) for timeouts

---

## Results Location

**Persistent Storage**: `/home/youruser/stable_scan/results/`

**Files**:
- `adaptive_scan_YYYYMMDD_HHMMSS_phase1_sampling.txt` - Phase 1 results
- `adaptive_scan_YYYYMMDD_HHMMSS_phase2_fulldecode.txt` - Phase 2 results

---

## Common Commands

### Check Scan Progress

```bash
./scripts/check_adaptive_scan_status.sh
```

### Manually Review TIMEOUT Files

```bash
# Extract TIMEOUT files from Phase 2 results
grep "^TIMEOUT" /home/youruser/stable_scan/results/adaptive_scan_*_phase2_fulldecode.txt | \
  awk -F'|' '{print $4}' > /tmp/timeout_files.txt
```

### Kill Stuck Processes

```bash
# Find stuck ffmpeg processes
ps aux | grep ffmpeg | grep -v grep

# Kill all ffmpeg processes (if needed)
pkill -9 ffmpeg
```

### Resume Scan

The adaptive scan automatically resumes from checkpoints:
- Phase 1: Skips already-processed files
- Phase 2: Skips already-processed files
- Just restart the scan - it will continue where it left off

---

## Troubleshooting

### High System Load

**Symptom**: Containers unhealthy, high load average
**Solution**: Reduce workers

```bash
# Edit run_adaptive_scan_persistent.sh
WORKERS=6  # Reduce from 12
WORKERS_FULL=4  # Reduce from 12
```

### Scan Stuck

**Symptom**: No progress for hours
**Solution**: Check for stuck processes

```bash
# Check active ffmpeg processes
pgrep -c ffmpeg

# Check screen session
screen -list

# Re-attach and check logs
screen -r adaptive_scan
```

### Results Lost

**Symptom**: Results file missing after reboot
**Solution**: Results should be in persistent location (not `/tmp`)
- Check: `/home/youruser/stable_scan/results/`
- If missing, restart scan - it will resume from previous checkpoints

---

## Workflow Summary

1. **Start Scan**: `./scripts/run_adaptive_scan_persistent.sh`
2. **Monitor Progress**: `./scripts/check_adaptive_scan_status.sh` (regularly)
3. **Wait for Completion**: ~40-60 hours total (varies by library size)
4. **Review TIMEOUT Files**: Manual playback test recommended
5. **Quarantine CORRUPT**: `./scripts/quarantine_corrupt_media.sh`
6. **Verify Radarr/Sonarr**: Check that re-downloads triggered

---

## Key Files

| Script | Purpose |
|--------|---------|
| `adaptive_corruption_scan.sh` | Main 2-phase orchestrator |
| `run_adaptive_scan_persistent.sh` | Wrapper with persistent storage |
| `check_adaptive_scan_status.sh` | Status checker with ETA |
| `quarantine_corrupt_media.sh` | Safe quarantine (move, not delete) |
| `npart_strict_worker.sh` | Phase 1 worker |
| `full_decode_worker.sh` | Phase 2 worker |

---

**For detailed documentation**: See [media-corruption-scanning.md](media-corruption-scanning.md)

