# Plex Subtitle Download Troubleshooting

## Issue
"Failed to download subtitle" when requesting English subtitles (e.g. OpenSubtitles) from Plex, including on remote iPad. The HTTP PUT to the server returns **200 OK**, but the UI shows failure—the actual error occurs during background processing.

### Update: not account-specific
The issue **affects both the admin account and the managed "Older kid" account** on the same iPad, and **subtitle download used to work** (including for the managed account). So the cause is **not** user permissions or restriction profiles—it is **server-side**: something changed on the Plex server, OpenSubtitles integration, or network. Focus troubleshooting on OpenSubtitles credentials, the `getAgent('library')` error, and Plex/OpenSubtitles updates or API changes.

## Server Check (2026-03-15)

- **Plex version:** 1.43.1.10540
- **Container:** `plex` (my-plex-image), Up and healthy
- **Config path in container:** `/config` (host path from `PLEX_CONFIG_PATH`)

### Log findings

1. **No OpenSubtitles plugin log**  
   There is no `com.plexapp.agents.opensubtitles.log` under  
   `Plex Media Server/Logs/PMS Plugin Logs/`.  
   This server uses **Plex TV Series** / **Plex Movie** (modern agents), not the legacy OpenSubtitles metadata agent. On-demand subtitle download is handled by the main server, not that legacy plugin.

2. **Metadata agent error during Transcode**  
   The main server log repeatedly shows:
   ```text
   ERROR - [Req#.../Transcode/.../MetadataAgentManager/getAgent] Unable to find metadata agent provider for identifier 'library'
   ```
   This occurs during Transcode requests. The subtitle-download flow may be resolving a provider by identifier `'library'` and failing when that agent is not found, which can lead to "Failed to download subtitle" even though the initial PUT returns 200.

3. **Transcode permission denial (likely unrelated to subtitle failure)**  
   ```text
   WARN - [Req#11573f/Transcode] Denying access due to session lacking permission to transcode key /library/metadata/33471
   ```
   This can affect managed users with restrictive profiles (see deep-dive below). **However**, since the same "Failed to download subtitle" happens for the **admin account** on the same iPad and subtitle download used to work for the managed account, this log line is likely from a **different** request (e.g. playback of another item). The main subtitle failure is probably the `getAgent('library')` error or OpenSubtitles, not this permission.

4. **OpenSubtitles credentials**  
   There is no `com.plexapp.agents.opensubtitles` entry in `Plug-in Support/Preferences/`.  
   For **on-demand** subtitles, Plex may still require an OpenSubtitles.org account to be linked in **Plex Settings** (not the legacy agent). If that link is missing, expired, or broken (e.g. after an OpenSubtitles API change), downloads can fail after the 200 response. **Re-linking or re-signing into OpenSubtitles in Plex is a top fix to try**, especially since the feature used to work.

---

## Deep dive: transcode permission error and “Older kid” accounts

### What the log line means

- **Message:** `Denying access due to session lacking permission to transcode key /library/metadata/33471`
- **Request:** `Req#11573f/Transcode` — the server is handling a **transcode** request (or something that goes through the transcode path, e.g. subtitle burn-in or preparation).
- **Key:** `/library/metadata/33471` — a specific library item (one episode or movie). The denial is for **this item**, for **this session**.

So the server is explicitly denying that the **current session** (the logged-in user) is allowed to transcode **that** piece of content.

### Why “Older kid” can trigger this

With a **managed user** and a **restriction profile** (e.g. “Older kid”):

1. **Restriction profiles are rating-based**  
   Plex’s [parental controls](https://support.plex.tv/articles/parental-controls/) use preset profiles that allow content up to certain ratings:
   - **Older kid:** TV-Y, G, TV-G, TV-PG, PG (and equivalents).
   - **Teen:** adds TV-14, PG-13, etc.

2. **Access and transcode are tied to the same policy**  
   For managed users, “can I play this?” and “can I transcode this?” are both decided by the same access rules. If the **content** is above the profile’s allowed rating, the user is not allowed to access it. When playback or subtitle download requires transcoding, the server then denies with **“session lacking permission to transcode key”** for that item — i.e. “this session is not allowed to use this content in a transcode.”

3. **Demon Slayer and “Older kid”**  
   Demon Slayer (e.g. *Kimetsu no Yaiba*) is typically **TV-14**. The “Older kid” profile only allows up to **TV-PG / PG**. So for that profile, the server will:
   - Restrict access to that show (or hide it), and/or  
   - Deny any transcode or transcode-related operation (including subtitle download if it goes through the transcode path) for that item.

So the transcode permission error for metadata id **33471** is consistent with: the iPad is signed in as a managed “Older kid” account, and the item **33471** is either above the profile’s rating or otherwise not allowed for that user. The server then denies the transcode (and with it, the subtitle download that depends on it).

### Other possible causes (less likely for “Older kid”)

- **“Allow Downloads” disabled**  
  Under [library access restrictions](https://support.plex.tv/articles/204232573-restricting-the-shares/), Plex Pass users can disable “Allow Downloads” per user. That affects downloading for offline use; it may or may not affect on-demand subtitle download, but it’s worth checking if that account has Downloads disabled.

- **Content not in a shared library**  
  If the item is in a library (or section) that isn’t shared with that managed user, the same “no permission” logic can apply and show up as transcode denied.

### What to do for the iPad “Older kid” account

1. **Confirm it’s account-specific**  
   On the same iPad, sign in as the **admin (Plex Home admin)** and try the same subtitle download for the same episode. If it works as admin and fails as “Older kid,” the restriction profile or library access for that managed user is the cause.

2. **Relax the profile for that user (if you’re okay with it)**  
   - In **Plex Web (admin):** **Settings → Manage → Users & Sharing → [the Older kid user] → Edit**.  
   - Change the restriction profile from **“Older kid”** to **“Teen”** (allows TV-14 / PG-13).  
   - Save and have the kid try again. If the error goes away, the cause was the rating ceiling.

3. **Keep “Older kid” but allow this show (Plex Pass)**  
   - Set the user’s restriction to **“None”** (or a custom profile) and use **custom restrictions** (ratings and/or labels).  
   - Add a **Label** (e.g. “Allowed for [name]”) to the show or library items you want to allow.  
   - In that user’s library access, allow content with that label.  
   This keeps a strict default but carves out specific titles.

4. **Don’t change profile**  
   If you want to keep “Older kid” and not allow TV-14 content, then that account is not allowed to play or use subtitles for Demon Slayer on the server. Use **manual subtitle files** (see workaround in “Recommended actions”) only for content that the profile already allows, or use the admin account for that show.

### Summary

| Factor | Effect |
|--------|--------|
| **Older kid profile** | Allows up to TV-PG / PG only. |
| **Demon Slayer (TV-14)** | Above that ceiling → server denies access/transcode for that user. |
| **Subtitle download** | Can go through transcode path → same “permission to transcode key” check → **“Failed to download subtitle”** when denied. |
| **Fix (if desired)** | Upgrade that user to “Teen,” or use custom labels (Plex Pass) to allow specific shows while keeping “Older kid” for everything else. |

## Recommended actions (server-side; not account-specific)

### 1. Re-link OpenSubtitles in Plex (top priority)
- In **Plex Web** or the server UI: **Settings → Account → OpenSubtitles** (or **Settings → Agents → [Movies/TV] → OpenSubtitles** in older UIs).
- Sign out of OpenSubtitles if shown, then sign in again with your **OpenSubtitles.org** username and password (create a free account if needed). OpenSubtitles may have changed auth or API; re-linking often fixes "used to work" failures.
- Save, then try downloading the same subtitle again.

### 2. Check Plex server and OpenSubtitles status
- Update the server to the latest stable version if you’re not already (you’re on 1.43.1).
- Check [Plex status](https://status.plex.tv/) and [OpenSubtitles](https://www.opensubtitles.org/) for outages or API issues.

### 3. Inspect logs right after a failed download
On the server (or via SSH):

```bash
# OpenSubtitles plugin log (if it exists; may not on modern agents)
docker exec plex tail -100 "/config/Plex Media Server/Logs/PMS Plugin Logs/com.plexapp.agents.opensubtitles.log"

# Main server log (errors and Transcode/getAgent)
docker exec plex tail -200 "/config/Plex Media Server/Logs/Plex Media Server.log" | grep -i -E "subtitle|opensub|getAgent|library|Transcode|Denying"
```

Reproduce the failure from the iPad, then run these immediately to see the exact errors.

### 4. Workaround: manual subtitle files (outside STARR) or automate with Bazarr
- **Manual:** You download the .srt separately; Sonarr and Radarr do not fetch subtitles.
- **Automated:** Deploy [Bazarr](https://www.bazarr.media/) on your stack to fetch subtitles for all Sonarr/Radarr content (e.g. 24 episodes at once). See [Bazarr Setup Guide](../guides/bazarr-setup.md).
- **Where to get .srt:**  
  - [OpenSubtitles.org – Demon Slayer: Kimetsu no Yaiba (English)](https://www.opensubtitles.org/en/ssearch/sublanguageid-eng/idmovie-743863) — pick the season/episode that matches your file.  
  - [SubScene](https://subscene.com/) — search for "Demon Slayer" or "Kimetsu no Yaiba", then choose the same release/season/episode if possible.
- **Naming and placement:** Put the `.srt` in the **same folder** as the video file and use the **same base name** as the video, with language code. Plex will detect it. Examples:
  - Video: `Demon Slayer - S01E01 - Cruelty.mkv` → Subtitle: `Demon Slayer - S01E01 - Cruelty.en.srt`
  - Or: `Kimetsu no Yaiba - S01E01.mkv` → `Kimetsu no Yaiba - S01E01.en.srt`
- **After adding the file:** In Plex, refresh the show (e.g. … → Refresh Metadata) or run a library scan so the new subtitle appears.

## Quick reference: log paths (inside container)

| Log | Path |
|-----|------|
| Main server | `/config/Plex Media Server/Logs/Plex Media Server.log` |
| Plugin logs | `/config/Plex Media Server/Logs/PMS Plugin Logs/` |
| OpenSubtitles (legacy) | `.../PMS Plugin Logs/com.plexapp.agents.opensubtitles.log` |

## References
- [Plex: Troubleshooting Subtitles](https://support.plex.tv/articles/200274058-troubleshooting-subtitles/)
- [Plex: Fetching Internet Sourced & Using Your Own Subtitle Files](https://support.plex.tv/articles/200288597-fetching-internet-sourced-using-your-own-subtitle-files/)
