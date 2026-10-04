#!/usr/bin/env bash
# Create /dev/sdb3 (ext4, label "kidsmedia") in the UNALLOCATED tail of the external USB drive.
# Never touches /dev/sdb2 (the NTFS data partition at /external/media).
# DRY RUN by default. Re-run with --apply to make changes.
# --skip-smart: proceed if the USB bridge cannot pass SMART through (owner decision, never default).
set -euo pipefail
APPLY=0; SKIP_SMART=0
for a in "$@"; do case "$a" in --apply) APPLY=1;; --skip-smart) SKIP_SMART=1;; *) echo "unknown arg: $a"; exit 2;; esac; done
DISK=/dev/sdb; DEV=sdb
EXP_SECTORS=7814037167; EXP_P2_START=264192; EXP_P2_SIZE=4511993856
P3_START=4512258048            # first 1 MiB-aligned sector after sdb2 ends (4512258047)
MNT=/external/kids; LABEL=kidsmedia; OWNER=1000:1004
TS=$(date +%Y%m%d-%H%M%S)
die(){ echo; echo "ABORT: $*" >&2; exit 1; }
run(){ echo "  + $*"; if [ "$APPLY" = 1 ]; then "$@"; fi; }
p2_intact(){ [ "$(cat /sys/block/$DEV/${DEV}2/start)" = "$EXP_P2_START" ] && [ "$(cat /sys/block/$DEV/${DEV}2/size)" = "$EXP_P2_SIZE" ]; }

[ "$(id -u)" = 0 ] || die "run with sudo"
echo "MODE: $([ $APPLY = 1 ] && echo 'APPLY — will make changes' || echo 'DRY RUN — read-only')"

echo "== 1. Identity checks =="
[ -b $DISK ] || die "$DISK missing"
model=$(xargs < /sys/block/$DEV/device/model)
[[ "$model" == *"Expansion Desk"* ]] || die "unexpected model: $model"
[ "$(cat /sys/block/$DEV/size)" = "$EXP_SECTORS" ] || die "disk size changed"
p2_intact || die "sdb2 geometry differs from what was audited"
[ ! -e /sys/block/$DEV/${DEV}3 ] || die "sdb3 already exists"
[ "$(blkid -o value -s TYPE ${DISK}2)" = ntfs ] || die "sdb2 is not ntfs"
[ "$(findmnt -n -S ${DISK}2 -o TARGET)" = /external/media ] || die "sdb2 not mounted at /external/media"
[ "$(blkid -p -o value -s PTTYPE $DISK)" = gpt ] || die "partition table is not GPT"
echo "  OK  model='$model'  table=GPT  sdb2 geometry unchanged  no sdb3"

echo "== 2. SMART health =="
SMT=""
for t in sat sat,12 sat,16 auto scsi; do
  H=$(smartctl -H -d "$t" $DISK 2>&1 || true)
  if echo "$H" | grep -qi "overall-health"; then SMT="$t"; break; fi
done
if [ -n "$SMT" ]; then
  A=$(smartctl -A -d "$SMT" $DISK 2>&1 || true)
  echo "  passthrough mode: -d $SMT"; echo "$H" | grep -i "overall-health" | sed "s/^/  /"
  echo "$A" | awk '$2 ~ /Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable|Reported_Uncorrect|Power_On_Hours|UDMA_CRC_Error/ {printf "  %-24s %s\n", $2, $10}'
  echo "$H" | grep -qi "PASSED" || die "SMART overall health is not PASSED"
  pend=$(echo "$A" | awk '$2=="Current_Pending_Sector"{print $10}'); unc=$(echo "$A" | awk '$2=="Offline_Uncorrectable"{print $10}')
  [ "${pend:-0}" = 0 ] && [ "${unc:-0}" = 0 ] || die "pending/uncorrectable sectors present — not building a library on this drive"
elif [ "$SKIP_SMART" = 1 ]; then
  echo "  WARNING: SMART unreadable through this USB bridge (uas). Proceeding because --skip-smart was given."
  echo "  kernel I/O/medium errors logged for sdb: $(journalctl -k --no-pager 2>/dev/null | grep -i sdb | grep -ciE 'I/O error|medium error|uncorrect' || true)"
else
  die "SMART not readable in any passthrough mode (tried sat, sat,12, sat,16, auto, scsi). Re-run with --skip-smart only if you accept proceeding without it."
fi

echo "== 3. Free space =="
last=$(sgdisk -E $DISK | tail -1)
[ "$last" -gt "$P3_START" ] || die "no free space after sdb2"
echo "  new partition: sectors $P3_START..$last = $(( (last - P3_START + 1) * 512 / 1000000000 )) GB"

echo "== 4. Partition table entry (GPT backed up first) =="
run sgdisk --backup=/root/sdb-gpt-backup-$TS.bin $DISK
run sgdisk -n 3:$P3_START:0 -t 3:8300 -c 3:$LABEL $DISK
if [ $APPLY = 1 ]; then
  [ -b ${DISK}3 ] || partx -a -n 3 $DISK
  sleep 2; [ -b ${DISK}3 ] || die "${DISK}3 did not appear"
  p2_intact || die "sdb2 geometry CHANGED — restore with: sgdisk --load-backup=/root/sdb-gpt-backup-$TS.bin $DISK"
  [ -z "$(blkid -p -o value -s TYPE ${DISK}3 2>/dev/null)" ] || die "${DISK}3 already carries a filesystem signature — refusing to format"
  echo "  OK  sdb3 present, sdb2 still intact, sdb3 blank"
else echo "  + partx -a -n 3 $DISK   (register sdb3 with the kernel; sdb2 stays mounted)"; fi

echo "== 5. Format ${DISK}3 as ext4 =="
run mkfs.ext4 -L $LABEL -m 0 -T largefile ${DISK}3

echo "== 6. Mount via fstab (nofail: a missing USB drive never blocks boot) =="
run cp /etc/fstab /etc/fstab.bak-$TS
if [ $APPLY = 1 ]; then
  uuid=$(blkid -o value -s UUID ${DISK}3); [ -n "$uuid" ] || die "no UUID on ${DISK}3"
  grep -q "$uuid" /etc/fstab || echo "UUID=$uuid  $MNT  ext4  defaults,noatime,nofail,x-systemd.device-timeout=30s  0  2" >> /etc/fstab
else echo "  + append: UUID=<new>  $MNT  ext4  defaults,noatime,nofail,x-systemd.device-timeout=30s  0  2"; fi
run mkdir -p $MNT
run systemctl daemon-reload
run mount $MNT
run mkdir -p "$MNT/Kids Movies" "$MNT/Kids TV"
run chown -R $OWNER $MNT

echo "== 7. Result =="
if [ $APPLY = 1 ]; then
  p2_intact && echo "  sdb2 intact ✓"; findmnt -n $MNT; df -h $MNT | tail -1; lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT $DISK
else echo "  DRY RUN complete — nothing changed. Re-run with --apply."; fi
