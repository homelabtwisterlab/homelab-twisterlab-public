# CLEANED COPY - REVIEW BEFORE PUBLISH
# Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/scripts/hermes/fix-edge-user-md.sh
# Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

#!/bin/bash
# fix-edge-user-md.sh - Sort le secret de USER.md et ramene le fichier sous la limite
set -u
M=/home/<USER>/.hermes/memories
S=/home/<USER>/.hermes/secrets
NEW=/tmp/edge-USER.md.new

echo "=== AVANT ==="
echo "  USER.md : $(wc -m < $M/USER.md) caracteres (limite 1375)"
echo "  backups existants : $(ls -1 $M/USER.md.bak.* 2>/dev/null | wc -l)"
echo "  permissions USER.md : $(stat -c '%a' $M/USER.md)"

echo "=== 1. Sauvegarde horodatee ==="
cp -p "$M/USER.md" "$M/USER.md.bak.$(date +%s)"
echo "  ok ($(ls -1 $M/USER.md.bak.* | wc -l) backups au total)"

echo "=== 2. Extraction du secret vers un fichier dedie ==="
mkdir -p "$S"; chmod 700 "$S"
PW=$(grep -i 'itsm.admin.test password:' "$M/USER.md" | sed 's/.*password = <SECRET-PLACEHOLDER> | tr -d '\r')
if [ -n "$PW" ]; then
  printf '%s\n' "$PW" > "$S/itsm-admin-test.txt"
  chmod 600 "$S/itsm-admin-test.txt"
  echo "  secret ecrit : $S/itsm-admin-test.txt ($(wc -c < "$S/itsm-admin-test.txt") octets, valeur NON affichee)"
  echo "  longueur du secret = <SECRET-PLACEHOLDER> caracteres"
else
  echo "  ATTENTION : aucun secret trouve dans USER.md"
fi

echo "=== 3. Durcissement des anciens backups (etaient world-readable) ==="
chmod 600 "$M"/USER.md.bak.* 2>/dev/null
echo "  $(ls -1 $M/USER.md.bak.* 2>/dev/null | wc -l) backups passes en 600"

echo "=== 4. Installation du nouveau USER.md ==="
install -m 600 "$NEW" "$M/USER.md"
rm -f "$NEW"

echo "=== APRES ==="
echo "  USER.md : $(wc -m < $M/USER.md) caracteres (limite 1375, marge $((1375 - $(wc -m < $M/USER.md))))"
echo "  permissions : $(stat -c '%a' $M/USER.md)"
echo "  contient encore 'password' ? $(grep -ci 'password' $M/USER.md) occurrence(s)"
echo "  secret toujours present ? $(test -s $S/itsm-admin-test.txt && echo OUI || echo NON)"
echo
echo "--- contenu final ---"
cat "$M/USER.md"
