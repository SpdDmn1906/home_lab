#!/usr/bin/env python3
"""Stop-gap while the USB drive is failing and mounted read-only (2026-10-05).

Dry-run unless --apply. Points every Sonarr series that can still receive downloads, and every wanted
Radarr movie without a file, at NAS folders; swaps the pick-list root folders to the NAS; adds the NAS
folders to the Plex kids libraries; searches the specific damaged episodes. Never touches files.
Movies that HAVE a file on the failing drive are deliberately left alone: Radarr unmonitors a movie
whose file disappears.
"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from starr import get, call, command, plex, plex_sections
APPLY = "--apply" in sys.argv
FAIL = ("/external/", "/kids/")
KIDS_TV, KIDS_MOV = "/data/Kids TV", "/data/Kids Movies"          # container paths (NAS Media share)
HOST = {"/data/": "/data/media/"}                                    # host side of the same share
def note(*a): print(("" if APPLY else "[dry-run] ") + " ".join(map(str, a)), flush=True)
def is_kids(p): return "/Kids " in p or p.startswith("/kids/")

# folders on the NAS
for d in ("/data/media/Kids TV", "/data/media/Kids Movies"):
    if not os.path.isdir(d):
        note("mkdir", d)
        if APPLY: os.makedirs(d)
# root folders
for app, new in (("radarr", KIDS_MOV), ("sonarr", KIDS_TV)):
    roots = {r["path"].rstrip("/"): r for r in get(app, "rootfolder")}
    if new not in roots:
        note(app, "add root folder", new)
        if APPLY: call(app, "POST", "rootfolder", {"path": new})

# Sonarr: series that can still receive downloads
DAMAGED = {"The Amazing World of Gumball": ("season", 7), "iCarly": ("episode", (4, 1)), "Little Lunch": ("episode", (1, 18))}
moved = []
for s in get("sonarr", "series"):
    if not s["path"].startswith(FAIL): continue
    st = s["statistics"]
    wants = s["monitored"] and (s["status"] in ("continuing", "upcoming") or st["episodeFileCount"] < st["episodeCount"])
    if s["title"] in DAMAGED or wants:
        root = KIDS_TV if is_kids(s["path"]) else "/TV Shows"
        note("sonarr repoint %-30s -> %s" % (s["title"][:30], root))
        moved.append((s, root))
if APPLY:
    for s, root in moved:
        call("sonarr", "PUT", "series/editor", {"seriesIds": [s["id"]], "rootFolderPath": root, "moveFiles": False})
    for s, _ in moved:
        command("sonarr", "RefreshSeries", seriesId=s["id"], timeout=900)
    for s, root in moved:
        a = get("sonarr", "series/%d" % s["id"]); note("  sonarr now", a["title"][:30], a["path"])
# damaged-episode searches
for s, _ in moved:
    if s["title"] not in DAMAGED: continue
    kind, what = DAMAGED[s["title"]]
    if kind == "season":
        note("sonarr search", s["title"], "season", what)
        if APPLY: command("sonarr", "SeasonSearch", seriesId=s["id"], seasonNumber=what, wait=False)
    else:
        if APPLY:
            ep = [e for e in get("sonarr", "episode?seriesId=%d" % s["id"]) if (e["seasonNumber"], e["episodeNumber"]) == what][0]
            command("sonarr", "EpisodeSearch", episodeIds=[ep["id"]], wait=False)
        note("sonarr search", s["title"], "S%02dE%02d" % what)

# Radarr: monitored movies without a file whose folder is on the failing drive
miss = [m for m in get("radarr", "movie") if m["path"].startswith(FAIL) and not m["hasFile"] and m["monitored"]]
groups = {}
for m in miss: groups.setdefault(KIDS_MOV if is_kids(m["path"]) else "/Movies", []).append(m["id"])
for root, ids in groups.items():
    note("radarr repoint %d wanted movies -> %s" % (len(ids), root))
    if APPLY: call("radarr", "PUT", "movie/editor", {"movieIds": ids, "rootFolderPath": root, "moveFiles": False})

# remove the failing drive's root folders from the pick lists (records/paths untouched)
for app in ("radarr", "sonarr"):
    for r in get(app, "rootfolder"):
        if r["path"].startswith(FAIL):
            note(app, "remove root folder from pick list", r["path"])
            if APPLY: call(app, "DELETE", "rootfolder/%d" % r["id"])

# Plex kids libraries: add the NAS folders (Plex sees the NAS Media share at /nas)
for title, loc in (("Kids Movies", "/nas/Kids Movies"), ("Kids TV Shows", "/nas/Kids TV")):
    s = plex_sections()[title]; locs = [l["path"] for l in s["Location"]]
    if loc not in locs:
        note("plex", title, "add location", loc)
        if APPLY:
            plex("PUT", "/library/sections/%s" % s["key"], [("agent", s["agent"]), ("scanner", s["scanner"]), ("language", s["language"])] + [("location", l) for l in locs + [loc]])
if APPLY:
    print("plex locations:", {t: [l["path"] for l in plex_sections()[t]["Location"]] for t in ("Kids Movies", "Kids TV Shows")})
    print("radarr roots:", [r["path"] for r in get("radarr", "rootfolder")], "| sonarr roots:", [r["path"] for r in get("sonarr", "rootfolder")])
print("done" if APPLY else "dry-run complete — nothing changed")
