#!/usr/bin/env python3
"""Kids migration, step 3d — make Plex read only the new copies.

1. Rescan the kids libraries and wait for the scan to finish.
2. Check every file Radarr/Sonarr now point at (under /kids) is a part in Plex.
3. Find items whose ONLY parts are on the old NTFS location — removing that location would make
   them vanish. Any found: stop and list them (unless --force).
4. --apply: remove the old location from each library (files are not touched), rescan, empty trash.

Location is removed BEFORE any source file is deleted (step 4), so Plex cleans up instead of
treating the folder as an unplugged drive. Watch history stays: items keep their new parts.
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from starr import get, plex, plex_sections  # noqa: E402

APPLY = '--apply' in sys.argv
FORCE = '--force' in sys.argv
LIBS = (('Kids Movies', '/external/media/Kids Movies', 1), ('Kids TV Shows', '/external/media/Kids TV', 4))


def scan(key):
    plex('GET', '/library/sections/%s/refresh' % key)
    time.sleep(5)
    while plex_sections_by_key()[key].get('refreshing'):
        time.sleep(10)


def plex_sections_by_key():
    return {s['key']: s for s in plex_sections().values()}


def items(key, ptype):
    mc = plex('GET', '/library/sections/%s/all?type=%d' % (key, ptype))['MediaContainer']
    out = []
    for m in mc.get('Metadata', []):
        parts = [p['file'] for md in m.get('Media', []) for p in md.get('Part', [])]
        label = m.get('title') if ptype == 1 else '%s S%02dE%02d' % (m.get('grandparentTitle'), m.get('parentIndex', 0), m.get('index', 0))
        out.append((label, parts))
    return out


def host(p):
    return '/external/kids' + p[len('/kids'):] if p.startswith('/kids/') else p


expected = {'Kids Movies': {host(m['movieFile']['path']) for m in get('radarr', 'movie')
                            if m['hasFile'] and m['movieFile']['path'].startswith('/kids/')},
            'Kids TV Shows': {host(f['path']) for s in get('sonarr', 'series') if s['path'].startswith('/kids/')
                              for f in get('sonarr', 'episodefile?seriesId=%d' % s['id'])}}
secs = plex_sections()
problems = 0
for title, old, ptype in LIBS:
    s = secs[title]
    print('== %s  locations: %s' % (title, [l['path'] for l in s['Location']]))
    scan(s['key'])
    its = items(s['key'], ptype)
    parts = {p for _, ps in its for p in ps}
    missing = sorted(expected[title] - parts)
    only_old = [(lbl, ps) for lbl, ps in its if ps and all(p.startswith(old + '/') for p in ps)]
    print('   items %d | files expected from Radarr/Sonarr %d | missing in Plex %d | items only on old location %d'
          % (len(its), len(expected[title]), len(missing), len(only_old)))
    for m in missing[:15]:
        print('     MISSING', m)
    for lbl, ps in only_old[:25]:
        print('     ONLY-OLD', lbl, ps[0][len(old) + 1:])
    problems += len(missing) + (0 if FORCE else len(only_old))
if not APPLY:
    sys.exit('dry-run complete — nothing changed' + ('' if not problems else ' (%d problems above)' % problems))
if problems:
    sys.exit('ABORT: resolve the items above first (or --force if the only-old items are expected)')
for title, old, ptype in LIBS:
    s = plex_sections()[title]
    locs = [l['path'] for l in s['Location'] if l['path'] != old]
    plex('PUT', '/library/sections/%s' % s['key'],
         [('agent', s['agent']), ('scanner', s['scanner']), ('language', s['language'])] + [('location', l) for l in locs])
    scan(s['key'])
    plex('PUT', '/library/sections/%s/emptyTrash' % s['key'])
    time.sleep(5)
    its = items(s['key'], ptype)
    left_old = sum(1 for _, ps in its for p in ps if p.startswith(old + '/'))
    print('%s: locations %s | items %d | parts still on old location %d'
          % (title, [l['path'] for l in plex_sections()[title]['Location']], len(its), left_old))
