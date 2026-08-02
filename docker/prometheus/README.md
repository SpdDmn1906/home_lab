# Prometheus config — captured from the live server, 2026-08-02

The `prometheus` container itself is still a bare, unmanaged `docker run` (no compose/Terraform ownership — verified via `docker inspect prometheus --format '{{json .Config.Labels}}'`, which returns only the base image's own maintainer label, no compose/Portainer provenance at all). Fixing that is separate, larger work.

This directory is **not yet wired to deploy anything** — it exists so the config that container actually reads (`prometheus.yml`, `rules/*.yml`, bind-mounted from `~/Docker/prometheus/` on the host) has a git history and a diffable source of truth, instead of only existing as an untracked file on one box. Edit here, then copy to `~/Docker/prometheus/` on the server and `curl -X POST http://localhost:9090/-/reload` — same manual-deploy reality as today, just no longer invisible to git.

`rules/cifs-mount.yml` predates this capture — it was already running live, undocumented in git, discovered during the 2026-08-01 secrets/PII audit.
`rules/adguard-slo.yml` and the `adguard_dns_probe` scrape job were added as part of Platform/IDP ladder Rung 1 (SLO mechanics) — see `personal-dev/drills/RUNG1_SLO_ADGUARD.md`.

Two other Prometheus config trees exist in this repo (`monitoring/prometheus/`, `docker/monitoring/prometheus/`) — **neither matches the live server**, confirmed by diffing against this capture. Don't edit those expecting it to affect anything real; reconciling/retiring them is separate follow-up work, not done here.
