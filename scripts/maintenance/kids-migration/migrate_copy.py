#!/usr/bin/env python3
"""Kids migration, step 2 — checksum-verified copy, NTFS partition -> ext4 kids partition.

Dry-run by default: builds the copy plan from Radarr/Sonarr + the filesystem and checks free
space. Pass --apply to copy. This script NEVER deletes or modifies a source file.

Per file: read source once while hashing (SHA-256) -> write <dst>.partial -> fsync -> drop the
destination from the page cache -> re-read it from disk and hash -> rename into place only if
the hashes match. Every verified file is appended to a manifest; reruns skip verified files,
so an interrupted run resumes where it stopped.

Folder names are kept as-is here. TRaSH renaming happens afterwards inside Radarr/Sonarr,
where it is a same-filesystem rename (instant), not another copy.
"""
import fcntl
import hashlib
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from starr import get  # noqa: E402

APPLY = '--apply' in sys.argv
STATE = os.path.expanduser('~/kids-migration')
MANIFEST = os.path.join(STATE, 'manifest.jsonl')
CHUNK = 8 << 20

# container path prefix -> host path prefix (Radarr/Sonarr mount /external/media at /external)
HOST = {'/external/': '/external/media/'}
SRC_MOVIES = '/external/media/Kids Movies'
SRC_TV = '/external/media/Kids TV'
DST_MOVIES = '/external/kids/media/movies'
DST_TV = '/external/kids/media/tv'
VIDEO = {'.mkv', '.mp4', '.avi', '.m4v', '.mov', '.wmv', '.ts', '.mpg', '.mpeg'}
# Never carried over: release-group executables (RARBG_DO_NOT_MIRROR.exe and the like)
SKIP_EXT = {'.exe', '.bat', '.cmd', '.com', '.scr', '.msi', '.lnk', '.url', '.vbs', '.js'}
# Folders verified byte-identical (SHA-256, 2026-10-04) to a folder that IS copied
SKIP_DIRS = {SRC_TV + '/Dream.Productions.S01.1080p.10bit.WEBRip.6CH.x265.HEVC-PSA'}


def host_path(p):
    p = p.rstrip('/')
    for c, h in HOST.items():
        if p.startswith(c):
            return h + p[len(c):]
    return p


def walk_files(d):
    for root, _, files in os.walk(d):
        for f in sorted(files):
            yield os.path.join(root, f)


def has_video(d):
    return any(os.path.splitext(f)[1].lower() in VIDEO for f in walk_files(d))


def build_plan():
    jobs, residue = [], []
    movies = get('radarr', 'movie')
    managed = {host_path(m['path']): m for m in movies if m['path'].startswith('/external/Kids Movies')}
    for name in sorted(os.listdir(SRC_MOVIES)):
        src = os.path.join(SRC_MOVIES, name)
        if os.path.isdir(src):
            jobs.append(('movie' if src in managed else 'movie-unmanaged', src, os.path.join(DST_MOVIES, name)))
    series = get('sonarr', 'series')
    managed_tv = {host_path(s['path']): s for s in series if s['path'].startswith('/external/Kids TV')}
    for name in sorted(os.listdir(SRC_TV)):
        src = os.path.join(SRC_TV, name)
        if not os.path.isdir(src):
            continue
        if src in managed_tv:
            jobs.append(('series', src, os.path.join(DST_TV, name)))
        elif src in SKIP_DIRS:
            residue.append((src, 'byte-identical duplicate of a copied folder'))
        elif has_video(src):
            jobs.append(('series-unmanaged', src, os.path.join(DST_TV, name)))
        else:
            residue.append((src, 'no video (subtitles/nfo/txt/png/exe leftovers or empty)'))
    return jobs, residue


def sha256_file(path, drop_cache=False):
    if drop_cache:
        fd = os.open(path, os.O_RDONLY)
        os.posix_fadvise(fd, 0, 0, os.POSIX_FADV_DONTNEED)
        os.close(fd)
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(CHUNK), b''):
            h.update(b)
    return h.hexdigest()


def copy_verified(src, dst):
    tmp = dst + '.partial'
    h = hashlib.sha256()
    with open(src, 'rb') as fi, open(tmp, 'wb') as fo:
        for b in iter(lambda: fi.read(CHUNK), b''):
            h.update(b)
            fo.write(b)
        fo.flush()
        os.fsync(fo.fileno())
    src_sha = h.hexdigest()
    dst_sha = sha256_file(tmp, drop_cache=True)
    if src_sha != dst_sha:
        os.remove(tmp)  # our own partial copy, never a source file
        raise IOError('checksum mismatch: %s' % src)
    st = os.stat(src)
    os.utime(tmp, (st.st_atime, st.st_mtime))
    os.rename(tmp, dst)
    return src_sha


def main():
    jobs, residue = build_plan()
    files, skipped = [], []
    for kind, src_dir, dst_dir in jobs:
        for f in walk_files(src_dir):
            if os.path.splitext(f)[1].lower() in SKIP_EXT:
                skipped.append(f)
            else:
                files.append((kind, f, dst_dir + f[len(src_dir):]))
    done = {}
    if os.path.exists(MANIFEST):
        for line in open(MANIFEST):
            r = json.loads(line)
            done[r['dst']] = r
    todo = [(k, s, d) for k, s, d in files
            if not (d in done and os.path.exists(d) and os.path.getsize(d) == done[d]['size'] == os.path.getsize(s))]
    need = sum(os.path.getsize(s) for _, s, _ in todo)
    vfs = os.statvfs('/external/kids')
    free = vfs.f_bavail * vfs.f_frsize

    by_kind = {}
    for k, s, _ in files:
        n, b = by_kind.get(k, (0, 0))
        by_kind[k] = (n + 1, b + os.path.getsize(s))
    print('PLAN  folders: %d   files: %d   already verified: %d   to copy: %d' % (len(jobs), len(files), len(files) - len(todo), len(todo)))
    for k, (n, b) in sorted(by_kind.items()):
        print('  %-17s %5d files %8.1f GB   (%d folders)' % (k, n, b / 1e9, sum(1 for j in jobs if j[0] == k)))
    print('  unmanaged folders (to add to Radarr/Sonarr in step 3):')
    for k, s, _ in jobs:
        if k.endswith('unmanaged'):
            print('     ', k, os.path.basename(s))
    print('  NOT copied — executables (%d):' % len(skipped), sorted(set(os.path.basename(x) for x in skipped)))
    print('  NOT copied — residue folders left in place (%d):' % len(residue))
    for r, why in residue:
        print('     ', os.path.basename(r), '—', why)
    print('SPACE need %.1f GB, free on /external/kids %.1f GB, headroom after %.1f GB' % (need / 1e9, free / 1e9, (free - need) / 1e9))
    if need > free * 0.97:
        sys.exit('ABORT: not enough free space on the kids partition')
    if not APPLY:
        print('dry-run complete — nothing copied. Re-run with --apply.')
        return

    os.makedirs(STATE, exist_ok=True)
    lock = open(os.path.join(STATE, '.copy.lock'), 'w')
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)  # refuses to run twice at once
    t0, copied, failures = time.time(), 0, []
    with open(MANIFEST, 'a') as man:
        for i, (kind, src, dst) in enumerate(todo, 1):
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            size = os.path.getsize(src)
            t1 = time.time()
            try:
                sha = copy_verified(src, dst)
            except Exception as e:  # keep going; failures are listed at the end and retried on rerun
                failures.append((src, str(e)))
                print('FAIL', src, e, flush=True)
                continue
            man.write(json.dumps({'kind': kind, 'src': src, 'dst': dst, 'size': size, 'sha256': sha,
                                  'ts': time.strftime('%Y-%m-%dT%H:%M:%S')}) + '\n')
            man.flush()
            copied += size
            rate = copied / max(time.time() - t0, 1)
            print('%5d/%d OK %7.1f MB %5.0f MB/s  avg %4.0f MB/s  ETA %4.1f h  %s' % (
                i, len(todo), size / 1e6, size / 1e6 / max(time.time() - t1, 0.001), rate / 1e6,
                (need - copied) / rate / 3600, dst[len('/external/kids/'):]), flush=True)
    print('COPY FINISHED  %.1f GB in %.1f h  failures: %d' % (copied / 1e9, (time.time() - t0) / 3600, len(failures)))
    for f in failures:
        print('  FAILED', *f)
    sys.exit(1 if failures else 0)


if __name__ == '__main__':
    main()
