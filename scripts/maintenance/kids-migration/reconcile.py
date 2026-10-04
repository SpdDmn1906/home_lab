#!/usr/bin/env python3
"""Kids migration, step 3a — reconcile the copy with what changed at the source during it.

Radarr/Sonarr kept running during the multi-hour copy. An upgrade replaces a source file, leaving a
stale copy at the destination. Dry-run by default: lists stale destination copies (manifest entries
whose source file no longer exists) and source files not yet copied. --apply removes the stale
destination copies — our own copies under /external/kids, never a source file. Then re-run
migrate_copy.py --apply to copy anything new.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import migrate_copy as mc  # noqa: E402

APPLY = '--apply' in sys.argv
entries = [json.loads(l) for l in open(mc.MANIFEST)]
latest = {}
for e in entries:
    latest[e['dst']] = e
stale = [e for e in latest.values() if not os.path.exists(e['src']) and os.path.exists(e['dst'])]
jobs, _ = mc.build_plan()
pending = []
for kind, src_dir, dst_dir in jobs:
    for f in mc.walk_files(src_dir):
        if os.path.splitext(f)[1].lower() in mc.SKIP_EXT:
            continue
        d = dst_dir + f[len(src_dir):]
        e = latest.get(d)
        if not (e and os.path.exists(d) and os.path.getsize(d) == e['size'] == os.path.getsize(f)):
            pending.append(f)
partials = [os.path.join(r, f) for r, _, fs in os.walk('/external/kids/media') for f in fs if f.endswith('.partial')]
print('stale destination copies (source gone): %d' % len(stale))
for e in stale:
    print('   ', e['dst'])
print('source files not yet copied/verified: %d' % len(pending))
for f in pending[:30]:
    print('   ', f)
print('leftover .partial files: %d' % len(partials), partials[:5])
if APPLY:
    for e in stale:
        if not e['dst'].startswith('/external/kids/'):
            sys.exit('refusing to delete outside /external/kids: ' + e['dst'])
        os.remove(e['dst'])
        print('removed stale copy', e['dst'])
    for p in partials:
        os.remove(p)
        print('removed partial', p)
if pending:
    sys.exit(3)          # something still needs copying: re-run migrate_copy.py --apply
if (stale or partials) and not APPLY:
    print('dry-run — re-run with --apply to remove the stale copies')
    sys.exit(4)
print('reconciled: every source file has a verified copy, no stale copies')
