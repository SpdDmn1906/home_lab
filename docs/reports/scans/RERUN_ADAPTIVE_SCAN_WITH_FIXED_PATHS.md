# Re-run Adaptive Scan with Fixed Paths

**Date**: January 10, 2026
**Purpose**: Re-run adaptive scan to catch files in `/Media/` directories that were missed due to path case mismatch bug

## Background

Previous scan results show:
- **0 files** from `/home/youruser/synology/Media/` (capital M) - **CONFIRMS THE BUG**
- **2,370 files** from `/home/youruser/synology/media/` (lowercase m) - wrong directory
- **4,294 total files** scanned (all from `/external/media/` paths)

**Conclusion**: All files in `/Media/` directories were completely missed!

## What Needs to Happen

The adaptive scan scripts have been fixed to use correct paths (`/Media/` with capital M). When re-run:

1. ✅ **Will skip**: Files already scanned from `/external/media/` paths (4,294 files)
2. ✅ **Will scan**: All files in `/Media/` directories (previously missed)
3. ✅ **Will skip**: Files from `/media/` (lowercase) if that directory exists (2,370 files)

## Resume Logic

The scan scripts automatically skip already-scanned files by:
- Reading previous results files
- Extracting file paths from column 8 (Phase 1) or column 5 (Phase 2)
- Filtering out matching paths from the file list

Since `/Media/` (capital) paths are different from `/media/` (lowercase) paths, files in `/Media/` won't be skipped (which is what we want).

## Running the Scan

### Option 1: Manual Execution (Recommended)

1. **Upload fixed scripts to server** (if not already there):
   ```bash
   scp scripts/npart_strict_scan_all_media.sh scripts/full_decode_scan_all_media.sh scripts/adaptive_corruption_scan.sh scripts/run_adaptive_scan_persistent.sh scripts/check_adaptive_scan_status.sh scripts/npart_strict_worker.sh scripts/full_decode_worker.sh scripts/full_decode_from_list.sh youruser@192.168.1.11:~/scripts/
   ```

2. **SSH to server**:
   ```bash
   ssh youruser@192.168.1.11
   ```

3. **Make scripts executable**:
   ```bash
   chmod +x ~/scripts/*.sh
   ```

4. **Start scan in screen session**:
   ```bash
   cd ~
   export RESULTS_DIR=/home/youruser/stable_scan/results
   export WORKERS=8
   export WORKERS_FULL=8
   screen -dmS adaptive_scan bash -c "bash scripts/run_adaptive_scan_persistent.sh 2>&1 | tee /tmp/adaptive_scan_\$(date +%Y%m%d_%H%M%S).log"
   ```

5. **Monitor progress**:
   ```bash
   # Re-attach to screen
   screen -r adaptive_scan

   # Or check status
   bash scripts/check_adaptive_scan_status.sh
   ```

### Option 2: Quick Start Script

Create and run this script on the server:

```bash
#!/bin/bash
# Quick start script for re-running adaptive scan

SCRIPT_DIR="$HOME/scripts"
RESULTS_DIR="/home/youruser/stable_scan/results"

# Kill existing screen session
screen -S adaptive_scan -X quit 2>/dev/null || true

# Start new scan
screen -dmS adaptive_scan bash -c "
    cd $HOME
    export RESULTS_DIR=$RESULTS_DIR
    export WORKERS=8
    export WORKERS_FULL=8
    bash $SCRIPT_DIR/run_adaptive_scan_persistent.sh 2>&1 | tee /tmp/adaptive_scan_\$(date +%Y%m%d_%H%M%S).log
"

echo "✅ Scan started in screen session 'adaptive_scan'"
echo "Monitor: screen -r adaptive_scan"
echo "Status: bash $SCRIPT_DIR/check_adaptive_scan_status.sh"
```

## Expected Results

### Files to Be Scanned

All files in:
- `/home/youruser/synology/Media/Movies` (previously missed)
- `/home/youruser/synology/Media/TV Shows` (previously missed)
- `/home/youruser/synology/Media/Movies - Kids` (previously missed) - **Includes Zootopia 2**
- `/home/youruser/synology/Media/TV Shows - Kids` (previously missed)

### Files to Be Skipped

- All files from `/external/media/` paths (already scanned in previous run)
- Files from `/home/youruser/synology/media/` if that directory exists (wrong directory, but will be skipped)

## Monitoring

### Check Status

```bash
bash ~/scripts/check_adaptive_scan_status.sh
```

### Check Screen Session

```bash
screen -list
screen -r adaptive_scan
```

### Check Progress

```bash
# Latest results file
ls -lt /home/youruser/stable_scan/results/adaptive_scan_*_phase1_sampling.txt | head -1

# Count files scanned
wc -l /home/youruser/stable_scan/results/adaptive_scan_*_phase1_sampling.txt | tail -1
```

## Expected Timeline

- **Phase 1**: Depends on number of files in `/Media/` directories
- **Phase 2**: Only files flagged in Phase 1 (typically 30-40% of files)
- **Workers**: 8 (conservative to avoid system overload)

## Important Notes

1. ✅ **Scripts are fixed** - All paths now use `/Media/` (capital M)
2. ✅ **Resume works** - Previous scan results are used to skip already-scanned files
3. ✅ **New files will be scanned** - Files in `/Media/` directories are new to the scan
4. ⚠️ **Files in `/media/` (lowercase) may be skipped** - But that's OK since actual files are in `/Media/` (capital)

---

**Status**: Ready to run
**Next Step**: Upload scripts and start scan on server

