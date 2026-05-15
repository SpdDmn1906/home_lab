# Bazarr Provider Troubleshooting & Configuration

## Problem Summary

Bazarr is running but not downloading subtitles because:

1. **Subscene** - Returns HTTP 403 (Forbidden) - Provider blocking scrapers
2. **YTS** - Returns HTTP 405 (Method Not Allowed) - Incorrect request method
3. **Shooter** - Returns HTTP 200 (OK) ✅ - **This one works**
4. **OpenSubtitles** - Daily quota exhausted (21/day limit reached)

## Solutions

### Option 1: Use Working Providers Only (Recommended)

Replace non-working providers with proven alternatives:

**Disable:**
- ❌ Subscene (403 blocking)
- ❌ YTS (405 error)
- ❌ OpenSubtitles (daily limit)
- ⚠️ Addic7ed (requires AntiCaptcha setup)

**Keep Enabled:**
- ✅ **Shooter** (working)
- ✅ **Podnapisi** (reliable, may have timeouts)
- ✅ **Argenteam** (good for Spanish)
- ✅ **GreekSubtitles** (good for Greek)

### Option 2: Add Reliable Alternatives

In Bazarr UI → **Settings → Providers**, enable these proven providers:

1. **Podnapisi**
   - No auth needed
   - Good coverage for multiple languages
   - Note: May timeout occasionally, but usually works

2. **OpenSubtitles.com (v2)**
   - Requires free account at https://www.opensubtitles.org/
   - Excellent subtitle coverage
   - 200 download/day limit (vs 21 with old API)
   - Sign in with username/password in Bazarr

3. **Shooter** ✅ (already working)
   - No auth needed
   - Excellent for Asian content

4. **Argenteam**
   - No auth needed
   - Great for Spanish subtitles
   - Reliable

### Option 3: Use Bazarr Embedded Subtitles (Fallback)

If you can't find external subtitles:

1. Go to **Settings → Embedded Subtitles**
2. Enable "Fallback to Embedded Subtitles"
3. This extracts subtitles from MKV files if available

## Why Subscene & YTS Are Failing

**Subscene (403 Forbidden):**
- The provider website blocks automated requests
- Requires special headers or authentication
- Not reliably scrapable by third-party tools

**YTS (405 Method Not Allowed):**
- The Bazarr provider implementation uses wrong HTTP method
- YTS API expects specific request format
- Would need custom configuration or provider update

**OpenSubtitles (Daily Limit):**
- Previous user already downloaded 21 subtitles today
- Free tier limited to 21/day (better accounts have higher limits)
- Will reset tomorrow at UTC 0

## Quick Fix: Reset & Reconfigure

### Step 1: Stop Bazarr
```bash
docker stop bazarr
```

### Step 2: Edit Config (Optional)
If you want to manually disable bad providers:
```bash
# Remove YTS from config
docker exec bazarr sed -i '/^yts: {}/d' /config/config/config.yaml

# Remove Subscene from config
docker exec bazarr sed -i '/^subscene: {}/d' /config/config/config.yaml
```

### Step 3: Restart
```bash
docker start bazarr
```

### Step 4: Configure in UI
1. Access Bazarr at `http://192.168.1.11:6767`
2. Go to **Settings → Providers**
3. Disable: Subscene, YTS, Addic7ed
4. Enable: Shooter, Podnapisi, Argenteam
5. (Optional) Add OpenSubtitles.com v2 with your free account

### Step 5: Test
1. Go to a Series/Movie you want subtitles for
2. Click the subtitle icon → **Search**
3. Check **History** to see results from working providers

## Expected Results

With this configuration, you should see:
- ✅ Shooter finding Asian content subtitles
- ✅ Podnapisi finding international subtitles
- ✅ Argenteam finding Spanish subtitles
- ✅ (With account) OpenSubtitles finding anything

## Why "No Download Activity"

The reason you saw "Finished searching for missing Series Subtitles" but no downloads:

1. Bazarr **was** searching
2. But Subscene & YTS were being blocked (403/405)
3. OpenSubtitles was throttled (daily limit)
4. So: **no results = no downloads**

Shooter was working but may not have found your specific content/language combination.

## Provider Recommendations by Language

| Language | Best Provider |
|----------|--------------|
| English  | Podnapisi, Shooter |
| Spanish  | Argenteam, Podnapisi |
| French   | Podnapisi |
| Italian  | Podnapisi |
| Portuguese | Podnapisi |
| Russian  | Podnapski, Shooter |
| Asian (CJK) | Shooter |
| Multiple | OpenSubtitles.com (with account) |

## Long-term Solution

For the most reliable subtitle downloads:
1. Create free account at https://www.opensubtitles.org/
2. Add it to Bazarr as "OpenSubtitles.com v2"
3. Use as primary provider (200/day limit)
4. Keep Podnapski as fallback
5. Use Shooter for Asian content

This gives you ~250+ subtitle downloads/day which should cover most use cases.
