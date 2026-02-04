# Documentation Index

**Last Updated**: 2026-01-09
**Purpose**: Quick reference guide to all documentation

---

## 🚀 Quick Start Guides

1. **[COMPREHENSIVE_FINAL_REVIEW.md](COMPREHENSIVE_FINAL_REVIEW.md)** ⭐ **START HERE**
   - Complete strategic overview
   - Goals, roadmap, and priorities
   - Updated with 4K and Fortress Mode goals

2. **[EPIC_SPRINT_PLAN.md](EPIC_SPRINT_PLAN.md)** ⭐ **EXECUTION PLAN**
   - Epic/Sprint breakdown (Problem → Solution → Implementation)
   - Acceptance criteria + dependencies
   - Practical weekly execution plan

3. **[TIER_SCORECARD.md](TIER_SCORECARD.md)** ⭐ **SCORECARD**
   - Current scores per infrastructure tier
   - Concrete plan to reach 90+ in each tier

4. **[IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md)** - **Execute First**
   - Step-by-step security fixes
   - Ready-to-run commands
   - Critical fixes with verification

5. **[AUDIT_SUMMARY.md](AUDIT_SUMMARY.md)** - Quick Reference
   - Executive summary of findings
   - Critical issues at a glance
   - Quick action items

---

## 📊 Infrastructure Analysis

4. **[SERVER_AUDIT_ANALYSIS.md](SERVER_AUDIT_ANALYSIS.md)**
   - Complete server audit (based on SSH)
   - Service-by-service analysis
   - Detailed findings and evidence

5. **[COMPREHENSIVE_FINAL_REVIEW.md](COMPREHENSIVE_FINAL_REVIEW.md)**
   - Strategic roadmap
   - Phase-by-phase implementation
   - Alignment with DevOps goals

---

## 🎬 4K & Performance Goals

6. **[PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md](PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md)** ⭐ **NEW**
   - Complete 4K playback strategy
   - External streaming optimization
   - Fortress mode implementation
   - HEVC compatibility solutions

7. **[PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md)** ⭐ **NEW (2025-12-30)**
   - Direct Play freezing investigation
   - USB NIC + USB media drive shared-hub risk
   - Evidence-driven next actions (MoCA/backhaul/client upgrade)

7a. **[MEDIA_CORRUPTION_ANALYSIS.md](MEDIA_CORRUPTION_ANALYSIS.md)** ⭐ **NEW (2026-01-02)**
   - H.264 NAL unit corruption analysis
   - Files downloaded during low storage periods
   - Detection and prevention strategies

7b. **[MEDIA_SCAN_RESULTS.md](MEDIA_SCAN_RESULTS.md)** ⭐ **NEW (2026-01-02)**
   - Results from scanning 90 movie files
   - 14 corrupted files identified (32.5% USB, 2% NAS)
   - Root cause: critically low storage (97-100% full)
   - Prevention strategy and next steps

7c. **[PLAYBACK_ISSUE_RESOLUTION.md](PLAYBACK_ISSUE_RESOLUTION.md)** ⭐ **NEW (2026-01-02)**
   - Executive summary of "Glory Road" playback freezing
   - File corruption confirmed via ffprobe
   - Action plan and resolution

7d. **[MEDIA_VALIDATION_GUIDE.md](MEDIA_VALIDATION_GUIDE.md)** ⭐ **NEW (2026-01-02)**
   - Comprehensive guide to using media validation scripts
   - Scanner modes: Quick, Smart, Deep
   - Automated post-download validation setup
   - **Note**: Manual validation superseded by automated adaptive scanning (see below)

7d1. **[docs/media-corruption-scanning.md](docs/media-corruption-scanning.md)** ⭐⭐ **NEW (2026-01-09)** ⭐ **PRODUCTION SYSTEM**
   - **Complete adaptive 2-phase corruption scanning system documentation**
   - Phase 1: Fast N-part sampling (20 parts × 10s)
   - Phase 2: Full-decode confirmation on flagged files
   - Quarantine workflow (safe move, not delete)
   - Performance tuning and worker configuration
   - False positive mitigation (subtitle warnings)
   - Historical context (Lightyear, Kids Movies deletion)
   - All scripts documented with usage examples
   - **Current production system** - actively used

7d1a. **[docs/media-scanning-quick-reference.md](docs/media-scanning-quick-reference.md)** ⭐ **NEW (2026-01-09)**
   - Quick reference guide for media corruption scanning
   - Common commands and configuration
   - Troubleshooting quick fixes
   - Workflow summary

7d1b. **[ADAPTIVE_SCAN_COMPLETION_SUMMARY.md](ADAPTIVE_SCAN_COMPLETION_SUMMARY.md)** ⭐ **NEW (2026-01-09)**
   - Complete summary of adaptive scanning system development
   - All accomplishments and achievements
   - Lessons learned and best practices
   - Future enhancement opportunities

7d2. **[SCAN_RESULTS_SUMMARY_20260109.md](SCAN_RESULTS_SUMMARY_20260109.md)** ⭐ **NEW (2026-01-09)**
   - January 2026 comprehensive adaptive scan results
   - Phase 1: 4,294 files (92% coverage)
   - Phase 2: 1,436 files (full-decode confirmation)
   - 504 CORRUPT files identified and quarantined
   - 174 TIMEOUT files (manual review needed)
   - Performance metrics and timing

7d3. **[CRITICAL_INCIDENT_REPORT.md](CRITICAL_INCIDENT_REPORT.md)** ⭐ **CRITICAL (2026-01-05)**
   - Kids Movies directory accidental deletion incident
   - Root cause analysis and permanent fix
   - Quarantine-based workflow implemented
   - Root-folder protection guarantees

7e. **[COMPREHENSIVE_DUPLICATE_ANALYSIS.md](COMPREHENSIVE_DUPLICATE_ANALYSIS.md)** ⭐ **NEW (2026-01-02)**
   - Complete duplicate detection results (corrected)
   - 232 duplicate TV files + 5 duplicate movies found
   - Internal NAS duplicates vs cross-location duplicates
   - ~110GB recoverable space

7f. **[DUPLICATE_CLEANUP_SUMMARY.md](DUPLICATE_CLEANUP_SUMMARY.md)** ⭐ **NEW (2026-01-02)**
   - Executive summary of duplicate cleanup
   - Phase 1 & 2 action plans
   - Step-by-step deletion guide

7g. **[PHASE1_MANUAL_CLEANUP.md](PHASE1_MANUAL_CLEANUP.md)** ⭐ **NEW (2026-01-02)**
   - Manual cleanup via Synology File Station
   - Files with CIFS permission issues
   - 48GB remaining to delete

7h. **[PHASE2_ACTION_GUIDE.md](PHASE2_ACTION_GUIDE.md)** ⭐ **NEW (2026-01-02)**
   - Sonarr/Radarr cleanup procedures
   - Rick and Morty, Bob's Burgers, Family Guy duplicates
   - Estimated 35-40GB additional savings

7i. **[REMAINING_DUPLICATES_ACTION_PLAN.md](REMAINING_DUPLICATES_ACTION_PLAN.md)** ⭐ **NEW (2026-01-02)**
   - After Phase 1: 349 files still duplicated (~51GB)
   - USB internal duplicates (American Dad: 22 files)
   - NAS internal duplicates (86 patterns)
   - Cross-location duplicates (90 episodes)
   - Quick wins: 14GB in 30 minutes
   - Weekend task: 36GB via Sonarr

7j. **[NAS_DELETION_RECOMMENDATIONS.md](NAS_DELETION_RECOMMENDATIONS.md)** ⭐ **NEW (2026-01-02)**
   - Comprehensive NAS analysis (5.4TB total, 96GB free)
   - JC (Janelle) folder: 1.8TB - UNTOUCHABLE
   - Tier 1 Quick Wins: 147GB (SC folder cleanup, poor quality kids movies, watched shows)
   - Tier 2 Optimization: 205GB (4K→1080p, collections, TV season pruning)
   - Tier 3 Deep Review: 100GB (unwatched content audit)
   - Total potential: ~452GB savings
   - Reality: Need 714GB to reach 15% free - storage expansion required

7k. **[FILE_STATION_DELETION_CHECKLIST.md](FILE_STATION_DELETION_CHECKLIST.md)** ⭐ **NEW (2026-01-02)**
   - Complete deletion checklist for Synology File Station
   - CIFS permissions require manual deletion via web UI
   - 4K movies (11 items, 58GB)
   - CAM/TELESYNC (9 items, 31GB)
   - Harry Potter Collection (49GB)
   - From series (49GB)
   - Family Guy Seasons 1-12 (138GB)
   - American Dad Seasons 1-10 (18GB)
   - SC folder cleanup (7GB)
   - **Total: ~376GB to free**
   - Includes checkbox format for easy tracking

7l. **[ORPHANED_MEDIA_CLEANUP_PLAN.md](ORPHANED_MEDIA_CLEANUP_PLAN.md)** ⭐ **NEW (2026-01-02)**
   - Radarr/Sonarr alignment strategy
   - **3.7TB of orphaned content discovered!**
   - 1,098 movies NOT in Radarr (~2.5TB)
   - 335 TV shows NOT in Sonarr (~1.3TB)
   - Category 1: Scattered episodes (30GB)
   - Category 2: Duplicate folders (200-300GB)
   - Category 3: Orphaned shows (900GB)
   - Category 4: Orphaned movies (2.5TB)
   - 3 strategic approaches: Consolidate, Delete All, or Add to Radarr/Sonarr

7m. **[SMART_CONSOLIDATION_PLAN.md](SMART_CONSOLIDATION_PLAN.md)** ⭐ **NEW (2026-01-02)** ⭐ **RECOMMENDED**
   - **Smart consolidation** - Move orphaned files INTO tracked folders
   - Accessed Radarr/Sonarr APIs to map tracked paths
   - **Phase 1**: South Park (28GB), Stranger Things (18GB) - ~34GB freed
   - **Phase 2**: Family Guy (40GB), American Dad (49GB) - ~89GB consolidated
   - **Phase 3**: Scattered episodes (~30GB) - automated consolidation
   - **Phase 4**: Review truly orphaned shows
   - Preserves content while ensuring everything is tracked
   - Includes detailed execution checklist with exact commands

7n. **[PHASE1_CONSOLIDATION_RESULTS.md](PHASE1_CONSOLIDATION_RESULTS.md)** ⭐ **NEW (2026-01-02)** ✅ **COMPLETED**
   - **Phase 1 execution results**
   - South Park: 238 episodes consolidated into tracked folder (pruned seasons 1-9)
   - Stranger Things: 17 episodes moved, 43 non-English subs deleted
   - Family Guy: 226 unique episodes identified for Phase 2
   - NAS duplicates deleted: ~3GB freed
   - 255+ new episodes now tracked by Sonarr
   - Storage remains critically low - Phase 2 needed

7o. **[PHASE2_REVISED_PRUNED_PLAN.md](PHASE2_REVISED_PRUNED_PLAN.md)** ⭐ **NEW (2026-01-02)** ⭐ **READY TO EXECUTE**
   - **Respects "last 10 seasons" pruning goal**
   - Family Guy: Keep only S13-14 (29 eps), delete S9-12 (52 eps)
   - American Dad: Keep only S11-18 (104 eps), delete S2-9 (96 eps)
   - **Delete first**: 148 old episodes (~34GB freed)
   - **Then move**: 133 recent episodes to NAS
   - **USB freed**: ~65GB total
   - **Sonarr impact**: +133 new episodes tracked
   - Includes exact commands for execution

8. **[SERVICE_OPTIMIZATION_RECOMMENDATIONS.md](SERVICE_OPTIMIZATION_RECOMMENDATIONS.md)**
   - Plex optimization (4K-ready)
   - STARR stack tuning
   - Performance recommendations

---

## 🔧 Configuration & Setup

8. **[OPTIMIZED_FSTAB_AND_CONFIGURATIONS.md](OPTIMIZED_FSTAB_AND_CONFIGURATIONS.md)**
   - Corrected fstab configuration
   - Docker-compatible paths
   - CIFS mount optimization

9. **[DOCKER_PATH_COMPATIBILITY.md](DOCKER_PATH_COMPATIBILITY.md)**
   - How fstab affects Docker
   - Path mapping documentation
   - Compatibility verification

10. **[docs/starr-stack-analysis.md](docs/starr-stack-analysis.md)**
    - STARR stack security analysis
    - Configuration recommendations

11. **[docs/starr-stack-migration-guide.md](docs/starr-stack-migration-guide.md)**
    - Step-by-step migration guide
    - Troubleshooting

---

## 🌐 Network & Connectivity

13. **[EERO_LATENCY_ANALYSIS.md](EERO_LATENCY_ANALYSIS.md)** ⚠️ **Wi‑Fi Issue**
    - Eero mesh latency analysis
    - Diagnostic results interpretation
    - Root cause identification

14. **[EERO_LATENCY_FIX_GUIDE.md](EERO_LATENCY_FIX_GUIDE.md)** ⚠️ **QUICK FIX**
    - Step-by-step latency fix (30 minutes)
    - Channel optimization guide
    - Verification steps

14. **[NETWORK_INFRASTRUCTURE_ACCOMPLISHMENTS.md](NETWORK_INFRASTRUCTURE_ACCOMPLISHMENTS.md)**
    - Network migration documentation
    - Current network state

15. **[NETWORK_MIGRATION_PLAN.md](NETWORK_MIGRATION_PLAN.md)**
    - Detailed migration guide
    - Network unification steps

16. **[NETWORK_SERVICE_AND_CIFS_FIXES.md](NETWORK_SERVICE_AND_CIFS_FIXES.md)**
    - Network service analysis
    - CIFS error fixes
    - Mount optimization

17. **[BOOT_ERRORS_AND_NETWORK_FIXES.md](BOOT_ERRORS_AND_NETWORK_FIXES.md)**
    - Boot error analysis
    - Network service conflicts
    - Fix procedures

18. **[DNS_SETUP_GUIDE.md](DNS_SETUP_GUIDE.md)**
    - Local DNS configuration
    - Name resolution setup

19. **[docs/network-setup.md](docs/network-setup.md)**
    - Network configuration guide
    - Optimization recommendations

---

## 🔒 Security

18. **[docs/running-infrastructure-audit.md](docs/running-infrastructure-audit.md)**
    - Security audit report
    - Risk assessment
    - Compliance checklist

19. **[docs/security.md](docs/security.md)**
    - Security best practices
    - Hardening guide

---

## 📱 Device Integration

20. **[DEVICE_INTEGRATION.md](DEVICE_INTEGRATION.md)**
    - Security camera setup
    - Gaming console optimization
    - Smart home integration

21. **[docs/gaming-network.md](docs/gaming-network.md)**
    - Gaming console network optimization
    - Port forwarding
    - QoS configuration

22. **[docs/security-cameras.md](docs/security-cameras.md)**
    - Camera security and setup
    - Network isolation
    - Troubleshooting

---

## 🏗️ Infrastructure Management

23. **[INFRASTRUCTURE_MANAGEMENT.md](INFRASTRUCTURE_MANAGEMENT.md)**
    - Terraform & Ansible IaC
    - Infrastructure automation

24. **[HOMELAB_ADVANCED_FEATURES.md](HOMELAB_ADVANCED_FEATURES.md)**
    - Advanced features guide
    - AdGuard Home + Unbound, parental controls (planned integration)
    - Remote access

---

## 📚 Additional Resources

25. **[docs/architecture.md](docs/architecture.md)**
    - Complete architecture overview
    - System design

26. **[docs/troubleshooting.md](docs/troubleshooting.md)**
    - Common issues and solutions
    - Diagnostic procedures

27. **[docs/plex-optimization.md](docs/plex-optimization.md)**
    - Plex-specific optimizations

28. **[docs/ups-recommendations.md](docs/ups-recommendations.md)**
    - UPS purchasing guide
    - Setup recommendations

---

## 📋 Removed/Consolidated Documents

The following documents were removed as duplicates/outdated:
- ~~CURRENT_INFRASTRUCTURE_ANALYSIS.md~~ → Consolidated into SERVER_AUDIT_ANALYSIS.md
- ~~INFRASTRUCTURE_STATUS_SUMMARY.md~~ → Consolidated into AUDIT_SUMMARY.md
- ~~INFRASTRUCTURE_RECOMMENDATIONS.md~~ → Consolidated into IMMEDIATE_ACTION_PLAN.md
- ~~NETWORK_INFRASTRUCTURE_SUMMARY.md~~ → Consolidated into NETWORK_INFRASTRUCTURE_ACCOMPLISHMENTS.md
- ~~QUICKSTART.md~~ → Consolidated into README.md quick start
- ~~GETTING_STARTED.md~~ → Consolidated into README.md
- ~~PROJECT_SUMMARY.md~~ → Consolidated into COMPREHENSIVE_FINAL_REVIEW.md

---

## 🎯 Document Priority for Your Goals

### For 4K & Fortress Mode Goals:
1. **PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md** - Complete implementation guide
2. **SERVICE_OPTIMIZATION_RECOMMENDATIONS.md** - Plex optimization details
3. **OPTIMIZED_FSTAB_AND_CONFIGURATIONS.md** - Storage optimization (critical for 4K)

### For Security Fixes:
1. **IMMEDIATE_ACTION_PLAN.md** - Step-by-step fixes
2. **docs/running-infrastructure-audit.md** - Security details

### For Infrastructure Overview:
1. **COMPREHENSIVE_FINAL_REVIEW.md** - Strategic roadmap
2. **SERVER_AUDIT_ANALYSIS.md** - Technical details

---

**Total Active Documents**: 30
**Status**: Organized and consolidated


---

## 🔧 Automation & Monitoring Scripts

- **[scripts/scan_media_integrity.sh](scripts/scan_media_integrity.sh)** ⭐ **NEW (2026-01-02)**
  - Automated media file corruption scanner (local execution)
  - Detects H.264 NAL unit errors and codec issues
  - Smart sampling mode (3×3min segments)
  - Parallel processing with 8 workers

- **[scripts/scan_media_server.sh](scripts/scan_media_server.sh)** ⭐ **NEW (2026-01-02)**
  - Server-ready media corruption scanner
  - Uses Docker ffmpeg (no native install required)
  - Optimized for remote execution via SSH

- **[scripts/radarr_targeted_refresh.sh](scripts/radarr_targeted_refresh.sh)** ⭐ **NEW (2026-01-02)**
  - Trigger Radarr API refresh/search for specific movies only
  - Avoids full library scan
  - Automatically finds movie IDs and triggers re-downloads

- **[scripts/find_duplicate_media.sh](scripts/find_duplicate_media.sh)** ⭐ **NEW (2026-01-02)**
  - Comprehensive duplicate detection (all types)
  - Finds internal NAS duplicates + cross-location duplicates
  - Identifies same movies/TV shows by title/year, not just filename
  - Optional corruption scanning for USB versions

- **[scripts/parallel_media_scan.sh](scripts/parallel_media_scan.sh)** ⭐ **NEW (2026-01-03)**
  - High-performance parallel media corruption scanner
  - 8 parallel workers with smart sampling
  - In-place terminal updates with progress bar and ETA
  - Scans 392 files in ~77 minutes

- **[scripts/scan_high_priority_media.sh](scripts/scan_high_priority_media.sh)** ⭐ **NEW (2026-01-03)**
  - Targeted scanner for Movies + Kids Movies + downloads
  - Designed for screen session execution
  - Same performance as parallel_media_scan.sh

- **[scripts/check_scan_progress.sh](scripts/check_scan_progress.sh)** ⭐ **NEW (2026-01-03)**
  - Monitor progress of long-running media scans
  - Shows real-time worker status and results
  - Safe to run while scan is in progress

- **[scripts/delete_corrupted_media.sh](scripts/delete_corrupted_media.sh)** ⚠️ **DEPRECATED**
  - **DO NOT USE** - Use quarantine script instead
  - Replaced by `quarantine_corrupt_media.sh`

- **[scripts/adaptive_corruption_scan.sh](scripts/adaptive_corruption_scan.sh)** ⭐⭐ **NEW (2026-01-09)** ⭐ **PRODUCTION**
  - Main 2-phase adaptive scan orchestrator
  - Phase 1: N-part sampling with strict error detection
  - Phase 2: Full-decode confirmation on flagged files
  - See `docs/media-corruption-scanning.md` for complete documentation

- **[scripts/run_adaptive_scan_persistent.sh](scripts/run_adaptive_scan_persistent.sh)** ⭐⭐ **NEW (2026-01-09)** ⭐ **PRODUCTION**
  - Wrapper script with persistent storage and screen session
  - Saves results to `/home/youruser/stable_scan/results/`
  - Performance monitoring during scan

- **[scripts/check_adaptive_scan_status.sh](scripts/check_adaptive_scan_status.sh)** ⭐⭐ **NEW (2026-01-09)** ⭐ **PRODUCTION**
  - Status checker with ETA calculations
  - System performance monitoring
  - Real-time progress tracking

- **[scripts/quarantine_corrupt_media.sh](scripts/quarantine_corrupt_media.sh)** ⭐⭐ **NEW (2026-01-09)** ⭐ **PRODUCTION**
  - Safe quarantine workflow (move, not delete)
  - Root-folder protection built-in
  - Automatic Radarr/Sonarr refresh + search
  - **Replaces delete_corrupted_media.sh**

---

## 📚 Session Summaries & Lessons Learned

- **[TODAYS_FINAL_SESSION_SUMMARY.md](TODAYS_FINAL_SESSION_SUMMARY.md)** ⭐ **NEW (2026-01-03)**
  - Comprehensive summary of January 3, 2026 session
  - All discoveries, fixes, and accomplishments
  - Session grade: A+ (95/100)
  - 356 GB freed, 24 corrupted files deleted

- **[LESSONS_LEARNED.md](LESSONS_LEARNED.md)** ⭐ **CRITICAL (2026-01-03)**
  - Essential lessons for Radarr/Sonarr automation
  - Operation timing requirements (2-5 minutes)
  - Monitoring status checks (CRITICAL)
  - Proper polling and status verification patterns

- **[TODAY_ACCOMPLISHMENTS.md](TODAY_ACCOMPLISHMENTS.md)** ⭐ **NEW (2026-01-03)**
  - Running log of session accomplishments
  - Storage cleanup progress
  - Corruption detection results
  - Duplicate elimination summary

- **[HIGH_PRIORITY_SCAN_RESULTS.md](HIGH_PRIORITY_SCAN_RESULTS.md)** ⭐ **NEW (2026-01-03)**
  - Detailed media scan results and analysis
  - 6.1% corruption rate across 392 files
  - Root cause identification (low storage downloads)

- **[SCAN_ANALYSIS_SUMMARY.md](SCAN_ANALYSIS_SUMMARY.md)** ⭐ **NEW (2026-01-03)**
  - Executive summary of scan results
  - Corruption breakdown by location
  - Action items and recommendations
