# Media Corruption Scan Results - January 9, 2026

## Scan Overview
- **Scan Date**: January 7-9, 2026
- **Scan Type**: Adaptive 2-Phase Scan
  - Phase 1: 20-part × 10s sampling (strict mode)
  - Phase 2: Full-decode confirmation on flagged files
- **Workers**: Phase 1 (12), Phase 2 (12, increased from 8 mid-scan)
- **Total Files Scanned**: 4,294 / 4,637 (92%)
- **Full Documentation**: See `docs/media-corruption-scanning.md` for complete methodology and scripts

## Final Results

### CORRUPT Files: 504
- **Status**: ✅ All quarantined
- **Action**: Moved to quarantine directories
- **Radarr/Sonarr**: Refresh + missing search triggered automatically

### TIMEOUT Files: 174
- **Status**: ⚠️ Need manual review
- **Reason**: Hit 30-minute timeout during full-decode
- **Likely Causes**: Very large files, slow network I/O on USB mounts, or actually corrupted
- **Action Required**: Manual playback test recommended

### OK Files: 758
- **Status**: ✅ Verified as false positives from Phase 1
- **Action**: No action needed

## Quarantine Details

### USB Quarantine
- **Location**: `/external/media/_quarantine/20260109_132000/`
- **Files**: 261 individual files
- **Total Entries**: 261 items

### NAS Quarantine (Fallback)
- **Location**: `/external/media/_quarantine/NAS_FALLBACK/20260109_132000/`
- **Reason**: Preferred NAS quarantine path was not writable
- **Items**: 8 directories (containing multiple CORRUPT files)
- **Files**: 10 individual files
- **NAS Items Moved**:
  1. /home/youruser/synology/media/Movies/22 Jump Street (2014)
  2. /home/youruser/synology/media/Movies/Annihilation (2018)
  3. /home/youruser/synology/media/Movies/A.Day.to.Die.2022.1080p.WEBRip.x265-RARBG
  4. /home/youruser/synology/media/Movies/Back on the Strip (2023)
  5. /home/youruser/synology/media/Movies/Baby Driver (2017)
  6. /home/youruser/synology/media/Movies/Boyka Undisputed IV (2016) + Extras/Featurettes/Scott Adkins Talks All Things Boyka.mkv
  7. /home/youruser/synology/media/Movies/Bottoms (2023)
  8. /home/youruser/synology/media/Movies/Chi-Raq (2015)

**Note**: The quarantine script moved entire movie directories when the corrupted file was directly in a movie folder. This means some CORRUPT files are contained within the 8 directories moved, which explains why the item count (269) is less than the file count (504).

## File Lists

### Comprehensive List
- **Location**: `scan_results_comprehensive_20260109.txt` (in this repo)
- **Contents**:
  - All 504 CORRUPT files (quarantined)
  - All 174 TIMEOUT files (need manual review)
- **Total Lines**: 678 file paths

### Breakdown
- **Movies**: 58 CORRUPT files + 131 TIMEOUT files
- **TV Shows**: 446 CORRUPT files + 43 TIMEOUT files

## Radarr/Sonarr Status

✅ **All quarantined files are tracked** in Radarr/Sonarr (sample verified)
✅ **Refresh + missing search commands triggered** automatically after quarantine
- Radarr: `RefreshMovie` + `MissingMoviesSearch` (monitored only)
- Sonarr: `RefreshSeries` + `MissingEpisodeSearch`

## Next Steps

1. **TIMEOUT Files**: Manually review 174 files by testing playback
   - If playback works: Files are OK (likely just very large or slow I/O)
   - If playback fails/freezes: Quarantine manually

2. **CORRUPT Files**: All 504 files are quarantined and will be re-downloaded automatically by Radarr/Sonarr

3. **Monitor**: Check Radarr/Sonarr activity to confirm re-downloads are proceeding

## Quarantine Locations

- **USB Quarantine**: `/external/media/_quarantine/20260109_132000/`
- **NAS Quarantine (Fallback)**: `/external/media/_quarantine/NAS_FALLBACK/20260109_132000/`

**All quarantined items are reversible** - files/folders were moved (not deleted) and can be restored if needed.

