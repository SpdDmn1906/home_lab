# 🐝 Solution: Renaissance: A Film by Beyoncé

## 🎯 The Problem
You are looking for **Renaissance: A Film by Beyoncé**.
*   **Official Status:** There is **NO official digital release** (WebDL, BluRay, DVD) as of March 2026.
*   **The Issue:** Your Radarr setup is likely configured to reject "low quality" releases like **CAM**, **TS** (TeleSync), or **HDCAM**.
*   **The Result:** Radarr sees the movie exists on trackers (as a Cam recording) but *hides* it from you because it doesn't meet your quality standards.

To guarantee success, we must force the system to accept what is available.

---

## 🛠️ Execution Plan

### Phase 1: Expand the Dragnet (Prowlarr)
We need to ensure you are searching the right places. Standard trackers might purge Cams, but these specific public trackers thrive on them.

1.  Open **Prowlarr** (`http://192.168.1.11:9696`).
2.  Go to **Indexers** → **Add Indexer**.
3.  Search for and add the following (if not already present):
    *   **1337x** (Excellent for general releases and leaks)
    *   **TorrentGalaxy** (Known for scene releases)
    *   **LimeTorrents** (Backup)
4.  Ensure they are **Enabled** and Syncing to Apps.

### Phase 2: Create the "Beyonce Protocol" Profile (Radarr)
We will create a special quality profile just for this movie so we don't mess up your other high-quality downloads.

1.  Open **Radarr** (`http://192.168.1.11:7878`).
2.  Go to **Settings** → **Profiles**.
3.  Click **+** to add a new profile.
4.  Name it: `Beyonce Search`
5.  **CRITICAL STEP:** In the "Qualities" list on the right, you MUST check/enable:
    *   **CAM**
    *   **TeleSync**
    *   **TeleCine**
    *   **Workprint**
6.  Save the profile.

### Phase 3: Update the Movie
1.  Go to the movie page for **Renaissance** in Radarr.
2.  Click **Edit** (wrench icon).
3.  Change **Quality Profile** to `Beyonce Search`.
4.  Click **Save**.
5.  Click **Search** (magnifying glass icon) on the movie page.

---

## 🤖 Automated Search & Diagnostic Script
I have created a script that will do the heavy lifting for you. It will:
1.  Verify your Prowlarr API key.
2.  Check which indexers are actually active.
3.  Check if Radarr is blocking the movie due to quality settings.
4.  Perform a "Deep Search" directly against Prowlarr to find *any* file matching the name, bypassing Radarr's filters.

**Run this command on your server:**

```bash
curl -sSL https://raw.githubusercontent.com/stephenchung/home-lab/main/scripts/find_beyonce_solution.sh | bash
```
*(Or manually run the script located at `scripts/find_beyonce_solution.sh` if you are local)*

---

## 📡 Advanced: The "Leak Trap" (Custom Format)
If you want to be notified the *second* a better version (like a leaked screener) drops:

1.  **Radarr** → **Settings** → **Custom Formats**.
2.  Add New → **Release Title**.
3.  Regex: `\b(Renaissance|Beyonce)\b.*(SCREENER|DVDSCR|R5|LEAK)`
4.  Go to **Profiles** → `Beyonce Search` → **Custom Formats** (on the right).
5.  Check your new format and give it a score of `1000`.
6.  This ensures that if a Screener leaks, Radarr will upgrade to it immediately, dumping the CAM version.

---

## 🏁 Summary
You were not finding results because the content you want is "unofficial" and your system is built for "official" quality. By enabling **1337x** and allowing **CAM/TS** qualities, you will find the available theater recordings immediately.
