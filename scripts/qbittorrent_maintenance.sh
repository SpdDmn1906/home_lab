#!/usr/bin/env bash
# qBittorrent maintenance: force recheck all, remove error torrents, enable uTP.
# Run on the media server (e.g. SSH to 192.168.1.11) or set QBITTORRENT_URL to the WebUI URL.

set -e

QB_URL="${QBITTORRENT_URL:-http://localhost:8080}"
QB_USER="${QBITTORRENT_USER:-admin}"
QB_PASS="${QBITTORRENT_PASSWORD:-admin}"
COOKIE_FILE="${TMPDIR:-/tmp}/qb_maintenance_cookies_$$.txt"
trap 'rm -f "$COOKIE_FILE"' EXIT

echo "qBittorrent maintenance (recheck all, remove errors, enable uTP)"
echo "Target: $QB_URL"
echo ""

# Login (cookie-based auth; success body is "Ok")
LOGIN_RESP=$(curl -s -c "$COOKIE_FILE" -X POST \
  -d "username=$QB_USER&password=$QB_PASS" \
  -H "Referer: $QB_URL/" \
  "$QB_URL/api/v2/auth/login")
if [ "$LOGIN_RESP" != "Ok" ]; then
  echo "Login failed (check username/password and URL). Response: $LOGIN_RESP"
  exit 1
fi
echo "Logged in."

# 1) Remove torrents in Error state
ERROR_HASHES=$(curl -s -b "$COOKIE_FILE" -H "Referer: $QB_URL/" \
  "$QB_URL/api/v2/torrents/info?filter=errored" | jq -r '.[].hash' 2>/dev/null | tr '\n' '|' | sed 's/|$//')
if [ -n "$ERROR_HASHES" ]; then
  COUNT=$(echo "$ERROR_HASHES" | tr '|' '\n' | wc -l)
  echo "Removing $COUNT torrent(s) in Error state..."
  curl -s -b "$COOKIE_FILE" -H "Referer: $QB_URL/" -X DELETE \
    "$QB_URL/api/v2/torrents?hashes=$ERROR_HASHES&deleteFiles=false" >/dev/null
  echo "Removed."
else
  echo "No torrents in Error state."
fi

# 2) Force recheck on all torrents
echo "Forcing recheck on all torrents..."
curl -s -b "$COOKIE_FILE" -H "Referer: $QB_URL/" -X POST \
  "$QB_URL/api/v2/torrents/recheck?hashes=all" >/dev/null
echo "Recheck started (may take a while in the UI)."

# 3) Enable uTP (bittorrent_protocol: 0 = TCP and μTP, 1 = TCP only, 2 = μTP only)
echo "Enabling uTP (TCP and μTP)..."
curl -s -b "$COOKIE_FILE" -H "Referer: $QB_URL/" -X POST \
  -d 'json={"bittorrent_protocol":0}' \
  -H "Content-Type: application/x-www-form-urlencoded" \
  "$QB_URL/api/v2/app/setPreferences" >/dev/null
echo "uTP enabled."

echo ""
echo "Done."
echo ""
echo "Port forwarding (PIA): get forwarded port with:"
echo "  docker exec gluetun cat /tmp/gluetun/forwarded_port"
echo "  # or: docker exec gluetun wget -qO- http://localhost:8000/v1/openvpn/portforwarded  (Gluetun control server)"
echo "Then set qBittorrent → Settings → Connection → Listening Port to that port."
