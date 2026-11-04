> **CLEANED COPY — REVIEW BEFORE PUBLISH**
> Source (private, NOT published): `homelabtwisterlab/homelab-twisterlab/demos/03-incident-validation/README.md`
> Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

# Démo 03 — Incident → Correction → Validation

## Objectif

Démontrer la capacité à gérer un incident complet : du symptôme à la cause racine,
en passant par la correction et la validation. Basé sur l'incident réel exit-75
(crash du gateway, 2026-10-06).

## Prérequis

- Accès lecture au dépôt GitHub (docs/incidents/exit-75.md)
- Compréhension de base de l'architecture TwisterLab (3 nœuds, Hermes, A2A)
- Accès SSH à Edge pour vérification (optionnel)

## Environnement cible

| Élément | Valeur |
|---|---|
| Incident | Crash du gateway Hermes, exit code 75 |
| Date | 2026-10-06 |
| Durée | ~14 minutes |
| Sévérité | Élevée (orchestration aveugle) |
| Statut | Résolu, cause racine identifiée |

> **Note sur l'expurgation** : Cette démo ne contient pas d'adresses IP ni de secrets. Les noms de services et ports sont des détails d'architecture publique.

## Procédure d'analyse d'incident

### Phase 1 — Symptômes

**Observation** : le service d'orchestration (port 8642) ne répond plus.
Les workers ne sont plus dispatchés. Le canal de notification timeout.

**Preuves** :
```
missed 3 consecutive liveness probes; exiting with code 75
polling degraded
```

### Phase 2 — Hypothèses

| # | Hypothèse | Vérification | Résultat |
|---|---|---|---|
| 1 | Le gateway a crashé (OOM, segfault) | Vérifier les logs | ❌ Pas de crash mémoire |
| 2 | Le répartiteur relance des workers fantômes | Vérifier les logs dispatcher | ✅ Confirmé |
| 3 | Le CPU est saturé par les workers | Vérifier top/htop | ✅ Confirmé (affamement asyncio) |
| 4 | Le port 8642 est bloqué | Vérifier netstat/ufw | ❌ Port ouvert |

### Phase 3 — Contrôles

```bash
# 1. Vérifier si le gateway tourne
curl -s http://<IP-PLACEHOLDER>:8642/health
# → timeout (service down)

# 2. Vérifier les logs
journalctl -u hermes-gateway --since "30 min ago" | grep -i "missed\|spawned\|reaped\|exit"

# 3. Vérifier les processus
ps aux | grep hermes | grep -v grep

# 4. Vérifier la charge CPU
top -bn1 | head -5
```

### Phase 4 — Cause racine confirmée

Le répartiteur (dispatcher) **relance ses workers après chaque suppression**.
Les tuer ne suffit pas : il en relance 2, puis 1. Chaque worker est un agent
complet (~100 Mo) avec accès terminal, qui consomme le CPU et **affame la
boucle d'événements asyncio** du gateway.

**Cause racine** : absence de circuit breaker dans le dispatcher. Le répartiteur
ne détecte pas que ses workers sont tués et les relance indéfiniment.

### Phase 5 — Correction appliquée

1. Désactivation du répartiteur automatique (`dispatch_in_gateway=false`)
2. L'orchestrateur (Hermes) route lui-même les tâches
3. Suppression des workers fantômes
4. Redémarrage du gateway

### Phase 6 — Validation (avant/après)

| Métrique | Avant | Après |
|---|---|---|
| Gateway port 8642 | Timeout | HTTP 200 ✅ |
| Workers fantômes | 3+ relancés | 0 |
| Charge CPU | Saturée | Normale |
| Notification channel | Timeout | Fonctionnel |
| Temps de récupération | ~14 min | < 1 min (redémarrage) |

### Phase 7 — Mesures préventives

1. **Désactiver le répartiteur automatique** — ne plus jamais relancer des workers sans validation
2. **Monitoring** — ajouter une sonde de vivacité (health check toutes les 30s)
3. **Circuit breaker** — si 3 sondes manquées, arrêter le dispatch et alerter
4. **Documentation** — post-mortem conservé dans `docs/incidents/exit-75.md`

## Limites et risques

- **Ne jamais supposer que tuer un processus suffit** — vérifier qu'il ne se relance pas
- **Toujours vérifier la charge CPU** avant de conclure qu'un service est « down »
- **Documenter la cause racine** même si elle semble évidente — la mémoire est volatile
- **Tester la reprise** après correction — ne pas supposer que le redémarrage suffit

## Résultats réels (mesurés — expurgés)

| Élément | Valeur | Date |
|---|---|---|
| Incident exit-75 | Crash gateway, 14 min d'indisponibilité | 2026-10-06 |
| Cause racine | Répartiteur relance des workers fantômes → affamement CPU | 2026-10-06 |
| Correction | Désactivation répartiteur auto + routage manuel | 2026-10-06 |
| Validation | Port 8642 HTTP 200, 0 workers fantômes | 2026-10-06 |
| Post-mortem | `docs/incidents/exit-75.md` | 2026-10-06 |

## Preuves (expurgées)

Les logs et captures d'écran sont stockés dans `evidence/` (non committés — contiennent des timestamps et des noms de processus).

Pour reproduire l'analyse : lire `docs/incidents/exit-75.md` et suivre la chronologie.

## Modèle pour futurs incidents

Cette démo sert de modèle pour documenter tout nouvel incident :

1. **Symptômes** — ce qui a été observé (avec preuves)
2. **Hypothèses** — ce qui aurait pu causer le problème
3. **Contrôles** — les commandes exécutées pour vérifier
4. **Cause racine** — la cause confirmée (ou « inconnue » si non résolue)
5. **Correction** — ce qui a été fait
6. **Validation** — preuve que le problème est résolu (avant/après)
7. **Mesures préventives** — ce qui évite la récidive
8. **Preuves** — logs, captures, hashes (expurgés)
