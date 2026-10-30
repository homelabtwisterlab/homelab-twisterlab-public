#!/bin/bash
# diagnostic.sh — Diagnostic Linux/Docker pour TwisterLab
# Lecture seule. Ne modifie rien.
# Usage : ./diagnostic.sh [edge-host]

EDGE_HOST="${1:-edge}"
EDGE_IP="<EDGE-IP>"

echo "=== Diagnostic Linux/Docker — TwisterLab ==="
echo "Hote: $EDGE_HOST ($EDGE_IP)"
echo "Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo ""

# 1. Etat general des conteneurs
echo "--- 1. Conteneurs actifs ---"
ssh "$EDGE_HOST" "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>&1
echo ""

# 2. Conteneurs arretes
echo "--- 2. Conteneurs arretes ---"
stopped=$(ssh "$EDGE_HOST" "docker ps -a --filter 'status=exited' --format '{{.Names}}' 2>/dev/null")
if [ -z "$stopped" ]; then
    echo "Aucun conteneur arrete."
else
    echo "$stopped"
fi
echo ""

# 3. Ports en ecoute
echo "--- 3. Ports critiques ---"
for port in 3000 3001 8080 8642 9090 18789; do
    # Note : test de connectivite HTTP sur / uniquement. Les endpoints de sante reels sont documentes dans le README (section 6).
    result=$(ssh "$EDGE_HOST" "curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:$port 2>/dev/null || echo 'FAIL'")
    echo "  Port $port: HTTP $result"
done
echo ""

# 4. Utilisation des ressources
echo "--- 4. Utilisation memoire ---"
ssh "$EDGE_HOST" "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>/dev/null | head -20" 2>&1
echo ""

# 5. Services systemd
echo "--- 5. Services cles ---"
for svc in ssh docker; do
    status=$(ssh "$EDGE_HOST" "systemctl is-active $svc 2>/dev/null")
    echo "  $svc: $status"
done
echo ""

# 6. Disque
echo "--- 6. Espace disque ---"
ssh "$EDGE_HOST" "df -h / | tail -1" 2>&1
echo ""

echo "=== FIN DU DIAGNOSTIC ==="

# Note : les codes HTTP 000 pour Forgejo/Grafana/Prometheus sont attendus car l'endpoint / ne sert pas de page. Utiliser les endpoints de sante documentes dans le README (section 6).