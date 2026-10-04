#!/usr/bin/env python3
"""Kids migration, step 1 — TRaSH folder layout, naming and settings.

Dry-run by default: prints every change it would make. Pass --apply to make them.

  1. Create the TRaSH layout on the kids partition: media/movies, media/tv
  2. Swap the (empty) /kids/Kids Movies + /kids/Kids TV root folders for /kids/media/{movies,tv}
  3. TRaSH naming: Radarr "Plex (TMDb)", Sonarr "Plex (TVDb)" — {tmdb-…}/{tvdb-…} folder tags,
     which current Jellyfin also parses (its PathExtensions.GetAttributeValue accepts {tmdb-…})
  4. Radarr: analyse video files on (TRaSH filenames use MediaInfo tokens);
     stop skipping the free-space check (imports were allowed onto a full disk)
  5. Disable — not delete — the hand-added Torznab indexers; their Prowlarr-synced twins stay
  6. Plex kids libraries: point at the new paths (old NTFS location kept until migration ends)
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from starr import APPS, call, get, plex, plex_sections  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
APPLY = '--apply' in sys.argv
TRASH_RADARR = json.load(open(os.path.join(HERE, 'trash', 'radarr-naming.json')))
TRASH_SONARR = json.load(open(os.path.join(HERE, 'trash', 'sonarr-naming.json')))
KIDS = '/external/kids'


def note(*a):
    print(('' if APPLY else '[dry-run] ') + ' '.join(map(str, a)))


def write(app, method, path, body=None):
    return call(app, method, path, body) if APPLY else None


# 1. Layout
for d in (KIDS + '/media/movies', KIDS + '/media/tv'):
    if not os.path.isdir(d):
        note('mkdir', d)
        if APPLY:
            os.makedirs(d)

# 2. Root folders
for app, new, old, kind in (('radarr', '/kids/media/movies', '/kids/Kids Movies', 'movie'),
                            ('sonarr', '/kids/media/tv', '/kids/Kids TV', 'series')):
    roots = {r['path'].rstrip('/'): r for r in get(app, 'rootfolder')}
    if new not in roots:
        note(app, 'add root folder', new)
        write(app, 'POST', 'rootfolder', {'path': new})
    in_use = [i['title'] for i in get(app, kind) if i['path'].startswith(old)]
    if old in roots and not in_use:
        note(app, 'remove empty root folder', old)
        write(app, 'DELETE', 'rootfolder/%d' % roots[old]['id'])
for d in (KIDS + '/Kids Movies', KIDS + '/Kids TV'):
    if os.path.isdir(d) and not os.listdir(d):
        note('rmdir empty', d)
        if APPLY:
            os.rmdir(d)

# 3. Naming
rn = get('radarr', 'config/naming')
new_rn = dict(rn, renameMovies=True,
              movieFolderFormat=TRASH_RADARR['folder']['plex-tmdb'],
              standardMovieFormat=TRASH_RADARR['file']['plex-tmdb'])
for k in ('movieFolderFormat', 'standardMovieFormat'):
    if rn[k] != new_rn[k]:
        note('radarr', k, repr(rn[k]), '->', repr(new_rn[k]))
write('radarr', 'PUT', 'config/naming/%d' % rn['id'], new_rn)

sn = get('sonarr', 'config/naming')
eps = TRASH_SONARR['episodes']
new_sn = dict(sn, renameEpisodes=True, multiEpisodeStyle=5,  # 5 = Prefixed Range
              seriesFolderFormat=TRASH_SONARR['series']['plex-tvdb'],
              seasonFolderFormat=TRASH_SONARR['season']['default'],
              standardEpisodeFormat=eps['standard']['default'],
              dailyEpisodeFormat=eps['daily']['default'],
              animeEpisodeFormat=eps['anime']['default'])
for k in ('seriesFolderFormat', 'seasonFolderFormat', 'standardEpisodeFormat', 'dailyEpisodeFormat', 'animeEpisodeFormat'):
    if sn[k] != new_sn[k]:
        note('sonarr', k, repr(sn[k]), '->', repr(new_sn[k]))
write('sonarr', 'PUT', 'config/naming/%d' % sn['id'], new_sn)

# 4. Radarr media management
mm = get('radarr', 'config/mediamanagement')
want = {'enableMediaInfo': True, 'skipFreeSpaceCheckWhenImporting': False}
changes = {k: (mm[k], v) for k, v in want.items() if mm[k] != v}
if changes:
    note('radarr media management', changes)
    write('radarr', 'PUT', 'config/mediamanagement/%d' % mm['id'], dict(mm, **want))

# 5. Legacy indexers
for app in APPS:
    for ix in get(app, 'indexer'):
        live = ix['enableRss'] or ix['enableAutomaticSearch'] or ix['enableInteractiveSearch']
        if ix['name'].lower().startswith('torznab') and live:
            note(app, 'disable legacy indexer', ix['name'])
            write(app, 'PUT', 'indexer/%d?forceSave=true' % ix['id'],
                  dict(ix, enableRss=False, enableAutomaticSearch=False, enableInteractiveSearch=False))

for app in APPS:
    for cf in get(app, 'customformat'):
        if cf.get('includeCustomFormatWhenRenaming'):
            note(app, 'custom format %r will appear in filenames via {[Custom Formats]}' % cf['name'])

# 6. Plex
secs = plex_sections()
for title, old, new in (('Kids Movies', KIDS + '/Kids Movies', KIDS + '/media/movies'),
                        ('Kids TV Shows', KIDS + '/Kids TV', KIDS + '/media/tv')):
    s = secs[title]
    locs = [l['path'] for l in s['Location']]
    target = [new if l == old else l for l in locs]
    if new not in target:
        target.insert(0, new)
    if target != locs:
        note('plex', title, locs, '->', target)
        if APPLY:
            plex('PUT', '/library/sections/%s' % s['key'],
                 [('agent', s['agent']), ('scanner', s['scanner']), ('language', s['language'])]
                 + [('location', l) for l in target])
print('done' if APPLY else 'dry-run complete — nothing changed')
