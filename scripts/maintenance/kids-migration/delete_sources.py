#!/usr/bin/env python3
"""Kids migration, step 4 — delete the NTFS originals, only once every gate passes.

  --snapshot   record the inode of every copied file (run right BEFORE rename.py --apply; renames
               keep inodes, so each copy can still be found after Radarr/Sonarr rename it)
  (no flag)    dry run: check every gate, print what would be deleted
  --apply      check every gate again, then delete

Gates (all must pass, or nothing is deleted):
  1. every manifest file still has its copy: same inode, same size (found wherever renames put it)
  2. every original is unchanged since it was copied (same size as recorded)
  3. every other file under the old folders is junk by an explicit rule: an executable, a file in
     a folder with no video, or a file in the verified-duplicate folder whose videos re-hash to a
     copied file. Any unexplained file blocks the run.
  4. Radarr/Sonarr have nothing pointing at the old folders; Plex has no part on them
"""
import hashlib
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import migrate_copy as mc  # noqa: E402
from starr import get, plex, plex_sections  # noqa: E402

STATE = os.path.expanduser('~/kids-migration')
SNAP = os.path.join(STATE, 'inodes.json')
APPLY = '--apply' in sys.argv
ROOTS = (mc.SRC_MOVIES, mc.SRC_TV)


def manifest():
    latest = {}
    for line in open(mc.MANIFEST):
        e = json.loads(line)
        latest[e['dst']] = e
    return latest


if '--snapshot' in sys.argv:
    snap = {}
    for dst, e in manifest().items():
        st = os.stat(dst)
        if st.st_size != e['size']:
            sys.exit('ABORT: copy changed size before snapshot: ' + dst)
        snap[dst] = [st.st_dev, st.st_ino, st.st_size]
    json.dump(snap, open(SNAP, 'w'))
    sys.exit('snapshot: %d copied files recorded in %s' % (len(snap), SNAP))

man = manifest()
snap = json.load(open(SNAP))
problems = []

# gate 1 — copies present (by inode, wherever renames moved them)
index = {}
for r, _, fs in os.walk('/external/kids/media'):
    for f in fs:
        p = os.path.join(r, f)
        st = os.lstat(p)
        index[(st.st_dev, st.st_ino)] = (p, st.st_size)
for dst, e in man.items():
    dev, ino, size = snap.get(dst, (None, None, None))
    hit = index.get((dev, ino))
    if not hit or hit[1] != e['size']:
        problems.append('copy missing/changed: ' + dst)

# gate 2 — originals unchanged
by_src = {e['src']: e for e in man.values()}
for src, e in by_src.items():
    if os.path.exists(src) and os.path.getsize(src) != e['size']:
        problems.append('original changed since copy: ' + src)

# gate 3 — classify every remaining file under the old folders
sha_copied = {e['sha256'] for e in man.values()}
delete, junk = [], []
for root in ROOTS:
    for top in sorted(os.listdir(root)):
        tdir = os.path.join(root, top)
        files = list(mc.walk_files(tdir)) if os.path.isdir(tdir) else [tdir]
        no_video = not any(os.path.splitext(f)[1].lower() in mc.VIDEO for f in files)
        for f in files:
            ext = os.path.splitext(f)[1].lower()
            if f in by_src:
                delete.append(f)
            elif ext in mc.SKIP_EXT:
                junk.append((f, 'executable'))
            elif no_video:
                junk.append((f, 'folder has no video'))
            elif tdir in mc.SKIP_DIRS:
                if ext in mc.VIDEO and mc.sha256_file(f) not in sha_copied:
                    problems.append('duplicate-folder video does NOT match any copy: ' + f)
                junk.append((f, 'verified duplicate'))
            else:
                problems.append('unexplained file (not copied, not junk): ' + f)

# gate 4 — nothing still points at the old folders
for m in get('radarr', 'movie'):
    if m['path'].startswith('/external/Kids Movies') or (m.get('movieFile') or {}).get('path', '').startswith('/external/Kids Movies'):
        problems.append('radarr still points at old folder: ' + m['title'])
for s in get('sonarr', 'series'):
    if s['path'].startswith('/external/Kids TV'):
        problems.append('sonarr still points at old folder: ' + s['title'])
for title, s in plex_sections().items():
    if any(l['path'] in ROOTS for l in s['Location']):
        problems.append('plex library still has the old location: ' + title)

size = sum(os.path.getsize(f) for f in delete) + sum(os.path.getsize(f) for f, _ in junk)
print('copied originals to delete: %d files | junk to delete: %d files | total %.1f GB'
      % (len(delete), len(junk), size / 1e9))
for why in sorted({w for _, w in junk}):
    print('   junk — %-20s %d files' % (why, sum(1 for _, w in junk if w == why)))
print('problems: %d' % len(problems))
for p in problems[:40]:
    print('   ', p)
if problems:
    sys.exit('BLOCKED — nothing deleted')
if not APPLY:
    sys.exit('dry-run: all gates pass — re-run with --apply to delete')

for f in delete + [f for f, _ in junk]:
    if not any(f.startswith(r + '/') for r in ROOTS):
        sys.exit('refusing to delete outside the old kids folders: ' + f)
    os.remove(f)
for root in ROOTS:  # empty directories, deepest first; then the old roots themselves
    for r, ds, fs in sorted(os.walk(root), key=lambda x: -x[0].count('/')):
        if r != root and not os.listdir(r):
            os.rmdir(r)
    if not os.listdir(root):
        os.rmdir(root)
left = [r for r in ROOTS if os.path.exists(r)]
print('deleted %d files (%.1f GB); old folders remaining: %s' % (len(delete) + len(junk), size / 1e9, left or 'none'))
