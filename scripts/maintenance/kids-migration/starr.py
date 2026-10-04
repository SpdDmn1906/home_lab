"""Tiny API helpers for Radarr, Sonarr and Plex on the media host (Python 3.6+, stdlib only).

API keys and the Plex token are read from the apps' own config files at runtime;
nothing secret is stored here.
"""
import json
import re
import time
import urllib.parse
import urllib.request

RADARR_CONFIG = '/usr/local/bin/radarr/config/config.xml'
SONARR_CONFIG = '/usr/local/bin/sonarr/config/config.xml'
PLEX_PREFS = '/app/plex/config/Plex Media Server/Preferences.xml'


def _key(path):
    return re.search(r'<ApiKey>([^<]+)', open(path).read()).group(1)


APPS = {'radarr': ('http://localhost:7878/api/v3/', _key(RADARR_CONFIG)),
        'sonarr': ('http://localhost:8989/api/v3/', _key(SONARR_CONFIG))}


def call(app, method, path, body=None, timeout=120):
    base, key = APPS[app]
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method,
                                 headers={'X-Api-Key': key, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
        return json.loads(raw.decode()) if raw else None


def get(app, path):
    return call(app, 'GET', path)


def command(app, name, wait=True, timeout=3600, **kw):
    """Queue a Radarr/Sonarr command and (by default) wait for it to finish."""
    c = call(app, 'POST', 'command', dict(name=name, **kw))
    t0 = time.time()
    while wait:
        s = get(app, 'command/%d' % c['id'])
        if s['status'] in ('completed', 'failed', 'aborted', 'cancelled', 'orphaned'):
            return s
        if time.time() - t0 > timeout:
            return s
        time.sleep(2)
    return c


PLEX_TOKEN = re.search(r'PlexOnlineToken="([^"]+)"', open(PLEX_PREFS).read()).group(1)


def plex(method, path, params=None):
    params = list(params or []) + [('X-Plex-Token', PLEX_TOKEN)]
    url = 'http://localhost:32400' + path + ('&' if '?' in path else '?') + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, method=method, headers={'Accept': 'application/json'})
    with urllib.request.urlopen(req, timeout=300) as r:
        raw = r.read()
        return json.loads(raw.decode()) if raw else None


def plex_sections():
    return {d['title']: d for d in plex('GET', '/library/sections')['MediaContainer']['Directory']}
