#!/usr/bin/env python3
"""Kids migration, step 3c — TRaSH folder + file renames inside Radarr/Sonarr (same filesystem: instant).

TRaSH's own "rename your folders" trick: editor -> same root folder -> move files: YES, then Rename.
Dry-run by default (counts + samples from the apps' rename previews). --apply does it.
Optional: --movie-ids 1,2 / --series-ids 3 to pilot on a few items first.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from starr import call, command, get  # noqa: E402

APPLY = '--apply' in sys.argv


def arg_ids(flag):
    if flag in sys.argv:
        return {int(x) for x in sys.argv[sys.argv.index(flag) + 1].split(',')}
    return None


def wait_idle(app, names):
    import time
    while any(c['name'] in names and c['status'] in ('queued', 'started') for c in get(app, 'command')):
        time.sleep(3)


mid, sid = arg_ids('--movie-ids'), arg_ids('--series-ids')
movies = [m for m in get('radarr', 'movie') if m['rootFolderPath'].rstrip('/') == '/kids/media/movies' and (mid is None or m['id'] in mid)]
series = [s for s in get('sonarr', 'series') if s['rootFolderPath'].rstrip('/') == '/kids/media/tv' and (sid is None or s['id'] in sid)]
if sid is not None and mid is None:
    movies = []
if mid is not None and sid is None:
    series = []
print('radarr: %d movies, sonarr: %d series in scope' % (len(movies), len(series)))
if not APPLY:
    sample = [p for m in movies[:5] for p in get('radarr', 'rename?movieId=%d' % m['id'])]
    for p in sample[:5]:
        print('  radarr file:', p['existingPath'], '->', p['newPath'])
    for s in series[:2]:
        for p in get('sonarr', 'rename?seriesId=%d' % s['id'])[:2]:
            print('  sonarr file:', p['existingPath'], '->', p['newPath'])
    sys.exit('dry-run complete — nothing changed')

if movies:
    call('radarr', 'PUT', 'movie/editor', {'movieIds': [m['id'] for m in movies], 'rootFolderPath': '/kids/media/movies', 'moveFiles': True})
    wait_idle('radarr', ('BulkMoveMovie', 'MoveMovie'))
    r = command('radarr', 'RenameMovie', movieIds=[m['id'] for m in movies], timeout=7200)
    print('radarr rename:', r['status'])
    left = sum(len(get('radarr', 'rename?movieId=%d' % m['id'])) for m in movies)
    lost = [x['title'] for x in (get('radarr', 'movie/%d' % m['id']) for m in movies if m['hasFile']) if not x['hasFile']]
    print('radarr: renames still pending %d | movies that lost their file %d %s' % (left, len(lost), lost[:10]))
if series:
    call('sonarr', 'PUT', 'series/editor', {'seriesIds': [s['id'] for s in series], 'rootFolderPath': '/kids/media/tv', 'moveFiles': True})
    wait_idle('sonarr', ('BulkMoveSeries', 'MoveSeries'))
    r = command('sonarr', 'RenameSeries', seriesIds=[s['id'] for s in series], timeout=7200)
    print('sonarr rename:', r['status'])
    for s in series:
        a = get('sonarr', 'series/%d' % s['id'])
        print('  %-38s files %3d -> %3d  pending renames %d  %s' % (a['title'], s['statistics']['episodeFileCount'], a['statistics']['episodeFileCount'],
                                                               len(get('sonarr', 'rename?seriesId=%d' % s['id'])), a['path']))
