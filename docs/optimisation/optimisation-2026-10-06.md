> **CLEANED COPY — REVIEW BEFORE PUBLISH**
> Source (private, NOT published): `homelabtwisterlab/homelab-twisterlab/docs/optimisation/optimisation-2026-10-06.md`
> Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

# Rapport d'optimisation — 2026-10-06

Généré le 2026-10-06 12:17

---

## CRITIQUE (1)

### dc-node — ram_libre
- **Valeur** : 1.8 Go
- **Seuil** : < 2.0 Go
- **Action** : Identifier le processus consommateur et le terminer, ou ajouter de la RAM

## RECOMMANDE (4)

### core — ram_libre
- **Valeur** : 3.8 Go
- **Seuil** : < 4.0 Go
- **Action** : Surveiller la tendance, prévoir un nettoyage des processus

### core — disque_usage_pct
- **Valeur** : 82.6 %
- **Seuil** : >= 80 %
- **Action** : Planifier un nettoyage, vérifier la rotation des logs

### edge — disque_usage_pct
- **Valeur** : 81 %
- **Seuil** : >= 80 %
- **Action** : Planifier un nettoyage, vérifier la rotation des logs

### edge — ports_0_0_0_0
- **Valeur** : [22, 3000, 5000, 5678, 8055, 8888]
- **Seuil** : ports sensibles exposés sur <IP-PLACEHOLDER>
- **Action** : Restreindre l'exposition des services sensibles à l'overlay Tailscale ou au LAN uniquement
