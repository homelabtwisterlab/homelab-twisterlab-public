# CLEANED COPY - REVIEW BEFORE PUBLISH
# Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/scripts/inventory.sh
# Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

#!/usr/bin/env bash
# Relevé d'inventaire Linux — Edge
# Usage: bash inventory.sh

echo "=== OS ==="
grep PRETTY /etc/os-release
uname -r

echo "=== CPU ==="
lscpu | grep -E 'Model name|^CPU\(s\)|Thread|Core'

echo "=== RAM ==="
free -h | head -2

echo "=== GPU ==="
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null \
  || echo "aucun GPU NVIDIA"

echo "=== DISK ==="
df -h / /home

echo "=== UPTIME ==="
uptime

echo "=== CONTAINERS ==="
docker ps --format '{{.Names}}|{{.Image}}|{{.Ports}}' 2>/dev/null || echo "docker indisponible"

echo "=== PORTS ==="
ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | sort -u

echo "=== DONE ==="
