#!/usr/bin/env python3
"""Kids migration, step 3b — point Radarr/Sonarr at the verified copies; add the unmanaged titles.

Dry-run by default. With --apply:
  - every movie under /external/Kids Movies -> /kids/media/movies (editor, move files: NO), refresh
  - every series under /external/Kids TV, plus Dream Productions -> /kids/media/tv, refresh
  - add Minions: Holiday Special + the two LeapFrog titles at their copied folders (no search)
Refuses to run while any source file is not yet verified in the manifest (run reconcile.py first).
Folder names are unchanged here; TRaSH renaming is rename.py.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from starr import call, command, get  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
APPLY = '--apply' in sys.argv
RADARR_OLD, RADARR_NEW = '/external/Kids Movies', '/kids/media/movies'
SONARR_OLD, SONARR_NEW = '/external/Kids TV', '/kids/media/tv'
EXTRA_SERIES_TVDB = [451408]  # Dream Productions: Sonarr entry pointed at a NAS folder that never existed
ADD_MOVIES = [  # tmdbId, copied folder name, profile name, why
    (764079, 'Illumination.Presents.Minions.Holiday.Special.2020.720p.WEB.h264-BAE[TGx]', '1080p Movies Max 4GB', 'upgradable to 1080p like the rest'),
    (20610, 'LeapFrog Letter Factory', 'Any', 'SD-only title; Any has upgrades off, so nothing gets searched'),
    (58632, 'LeapFrog Numbers Ahoy (2010)', 'Any', 'SD-only title'),
]

if subprocess.call([sys.executable, os.path.join(HERE, 'reconcile.py')], stdout=subprocess.DEVNULL) != 0:
    sys.exit('ABORT: reconcile.py reports unverified or stale files — fix those first')


def chunks(xs, n=50):
    for i in range(0, len(xs), n):
        yield xs[i:i + n]


# Radarr
movies = [m for m in get('radarr', 'movie') if m['path'].startswith(RADARR_OLD + '/')]
with_file = {m['id'] for m in movies if m['hasFile']}
print('radarr: %d kids movies to repoint (%d with files)' % (len(movies), len(with_file)))
have = {m['tmdbId'] for m in get('radarr', 'movie')}
profiles = {p['name']: p['id'] for p in get('radarr', 'qualityprofile')}
for tmdb, folder, prof, why in ADD_MOVIES:
    path = os.path.join(RADARR_NEW, folder)
    print('radarr: add tmdb %d at %s [%s — %s]%s' % (tmdb, path, prof, why, ' (ALREADY PRESENT — skip)' if tmdb in have else ''))
    if not os.path.isdir('/external/kids/media/movies/' + folder):
        sys.exit('ABORT: copied folder missing: ' + folder)
series = [s for s in get('sonarr', 'series') if s['path'].rstrip('/').startswith(SONARR_OLD + '/') or s['tvdbId'] in EXTRA_SERIES_TVDB]
before_eps = {s['id']: s['statistics']['episodeFileCount'] for s in series}
print('sonarr: %d series to repoint (%d episode files)' % (len(series), sum(before_eps.values())))
if not APPLY:
    sys.exit('dry-run complete — nothing changed')

for ids in chunks([m['id'] for m in movies]):
    call('radarr', 'PUT', 'movie/editor', {'movieIds': ids, 'rootFolderPath': RADARR_NEW, 'moveFiles': False})
for tmdb, folder, prof, _ in ADD_MOVIES:
    if tmdb in have:
        continue
    lk = get('radarr', 'movie/lookup/tmdb?tmdbId=%d' % tmdb)
    lk.update(path=os.path.join(RADARR_NEW, folder), rootFolderPath=RADARR_NEW, qualityProfileId=profiles[prof],
              monitored=True, minimumAvailability='released', addOptions={'searchForMovie': False})
    added = call('radarr', 'POST', 'movie', lk)
    movies.append(added)
r = command('radarr', 'RefreshMovie', movieIds=[m['id'] for m in movies], timeout=7200)
print('radarr refresh:', r['status'])
after = {m['id']: m for m in get('radarr', 'movie')}
lost = [after[i]['title'] for i in with_file if not after[i]['hasFile']]
wrong = [after[m['id']]['title'] for m in movies if not after[m['id']]['path'].startswith(RADARR_NEW + '/')]
outside = [after[m['id']]['title'] for m in movies if after[m['id']]['hasFile'] and not after[m['id']]['movieFile']['path'].startswith(RADARR_NEW + '/')]
added_ok = [(a['title'], 'hasFile=%s' % a['hasFile']) for a in after.values() if a['tmdbId'] in [x[0] for x in ADD_MOVIES]]
print('radarr: lost files %d %s | path not repointed %d %s | file outside new root %d %s' % (len(lost), lost[:10], len(wrong), wrong[:10], len(outside), outside[:10]))
print('radarr: added', added_ok)

for ids in chunks([s['id'] for s in series]):
    call('sonarr', 'PUT', 'series/editor', {'seriesIds': ids, 'rootFolderPath': SONARR_NEW, 'moveFiles': False})
for s in series:
    command('sonarr', 'RefreshSeries', seriesId=s['id'], timeout=1800)
after_s = {s['id']: s for s in get('sonarr', 'series')}
for s in series:
    a = after_s[s['id']]
    flag = '' if a['statistics']['episodeFileCount'] >= before_eps[s['id']] and a['path'].startswith(SONARR_NEW + '/') else '  <-- CHECK'
    print('sonarr: %-38s %3d -> %3d files  %s%s' % (a['title'], before_eps[s['id']], a['statistics']['episodeFileCount'], a['path'], flag))
sys.exit(1 if (lost or wrong or outside) else 0)
