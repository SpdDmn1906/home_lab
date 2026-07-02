#AdGuard DNS Blocked Domains Analyzer

import json
from collections import defaultdict

LOG = "/home/stephen/querylog.local.json"
TESTLOG = "/home/stephen/Documents/Repos/personal-dev/drills/sample_querylog.json"

total = 0
blocked = 0
counts = defaultdict(int)

with open(LOG) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        total += 1
        domain = rec.get("QH", "")
        counts[domain] += 1
        result = rec.get("Result", {})
        if result.get("IsFiltered", False):
            blocked += 1

assert sum(counts.values()) == total
print(f"Total: {total}")
print(f"Blocked: {blocked}\n")

print("=================")
print("Top 20 blocked")
print("=================")

top = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:20]
for domain, count in top:
    print(f"{domain} - {count}")