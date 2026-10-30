# Démo 02 — Diagnostic Linux / Docker

## Objectif

Démontrer la capacité à diagnostiquer l'état des conteneurs Docker sur Edge,
détecter un service indisponible et isoler la cause avec des commandes reproductibles.

## Prérequis

- Accès SSH à Edge depuis Core
- Clé SSH configurée (`~/.ssh/<votre-cle-ssh>`)
- Docker installé et fonctionnel sur Edge

## Environnement cible

| Élément | Valeur |
|---|---|
| Hôte | Edge — Ubuntu 24.04.5 LTS |
| Docker | 20 conteneurs actifs (mesuré le 2026-10-27) |
| Services clés | Forgejo (3000), Grafana (3001), OpenClaw (18789), Prometheus (9090) |
| Réseau | Tailscale overlay |

> **Note sur l'expurgation** : Les adresses IP LAN/Tailscale sont remplacées par des placeholders dans cette version publique. Les valeurs réelles sont documentées dans la documentation privée (INFRASTRUCTURE.md).

## Commandes de diagnostic

### 1. État général des conteneurs

```bash
ssh edge "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

**Résultat attendu** : liste des 20 conteneurs avec leur statut (Up/Exited) et ports mappés.

### 2. Détecter les conteneurs arrêtés

```bash
ssh edge "docker ps -a --filter 'status=exited' --format '{{.Names}}\t{{.Status}}\t{{.Image}}'"
```

**Résultat attendu** : liste vide (aucun conteneur arrêté) ou liste des conteneurs à investiguer.

### 3. Vérifier les journaux d'un service

```bash
ssh edge "docker logs --tail 50 <container_name> 2>&1"
```

**Résultat attendu** : logs récents du service, sans erreurs critiques.

### 4. Vérifier les ports en écoute

```bash
ssh edge "ss -tlnp | grep -E ':(3000|3001|8080|8642|9090|18789)'"
```

**Résultat attendu** : chaque port est en écoute (LISTEN) avec le processus associé.

### 5. Vérifier l'utilisation des ressources

```bash
ssh edge "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'"
```

**Résultat attendu** : CPU < 50%, mémoire < 80% par conteneur.

### 6. Vérifier la connectivité inter-services

```bash
ssh edge "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000"  # Forgejo
ssh edge "curl -s -o /dev/null -w '%{http_code}' http://localhost:3001/api/health"  # Grafana
ssh edge "curl -s -o /dev/null -w '%{http_code}' http://localhost:9090/-/healthy"  # Prometheus
```

**Résultat attendu** : 200 pour chaque service.

## Scénario de panne simulée (diagnostic uniquement)

### Symptôme
Le service Forgejo (port 3000) ne répond plus. Les utilisateurs ne peuvent pas accéder au dépôt git.

### Hypothèses
1. Conteneur Forgejo arrêté (crash, OOM)
2. Port 3000 occupé par un autre processus
3. Problème réseau (firewall, DNS)

### Contrôles (lecture seule)
```bash
# 1. Le conteneur tourne-t-il ?
ssh edge "docker ps --filter name=forgejo --format '{{.Names}}\t{{.Status}}'"

# 2. Quels sont les derniers logs ?
ssh edge "docker logs --tail 30 forgejo 2>&1"

# 3. Le port est-il en écoute ?
ssh edge "ss -tlnp | grep ':3000'"

# 4. Le conteneur a-t-il été tué par l'OOM killer ?
ssh edge "dmesg | grep -i 'oom\|killed process' | tail -5"
```

### Isolation de la cause (lecture seule)
```bash
# Vérifier l'utilisation mémoire du conteneur
ssh edge "docker stats --no-stream forgejo"

# Vérifier les limites de ressources
ssh edge "docker inspect forgejo --format '{{.HostConfig.Memory}} {{.HostConfig.CpuShares}}'"
```

## Remédiation (hors démo — ne pas exécuter sans autorisation)

> **⚠️ Ces commandes modifient l'état du système. Elles sont documentées pour référence mais ne font PAS partie de la démo de diagnostic en lecture seule.**

```bash
# Si le conteneur est arrêté, le redémarrer manuellement après diagnostic
ssh edge "docker start forgejo"

# Vérifier le rétablissement
ssh edge "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000"
```

### Preuve de rétablissement (vérification post-remédiation)
```bash
ssh edge "docker ps --filter name=forgejo --format '{{.Names}}\t{{.Status}}'"
# → forgejo ... Up X minutes
```

## Limites et risques

- **Ne jamais redémarrer un service sans diagnostic préalable** (principe : comprendre avant d'agir)
- **Ne jamais exécuter `docker restart` automatiquement** — toujours vérifier les logs d'abord
- **Edge a RAM limitée** — surveiller l'utilisation avant de lancer des conteneurs supplémentaires
- **Ne pas modifier les volumes Docker** sans backup (`docker volume ls`, `docker volume inspect`)

## Résultats réels (mesurés — expurgés)

| Test | Résultat | Date |
|---|---|---|
| docker ps (20 conteneurs) | 20 Up, 0 Exited | 2026-10-27 |
| Port 3000 (Forgejo) | 000 (endpoint / non servi — utiliser l'endpoint dédié) ⚠️ | 2026-10-27 |
| Port 3001 (Grafana) | 000 (endpoint /api/health attendu) ⚠️ | 2026-10-27 |
| Port 9090 (Prometheus) | 000 (endpoint /-/healthy attendu) ⚠️ | 2026-10-27 |
| Port 8642 (Hermes Edge) | 404 (endpoint /health attendu) ⚠️ | 2026-10-27 |
| Port 18789 (OpenClaw) | 200 ✅ | 2026-10-27 |
| docker stats (mémoire) | < 80% par conteneur | 2026-10-27 |

## Preuves (expurgées)

Les captures d'écran et logs sont stockés dans `evidence/` (non committés — contiennent des IPs et des noms d'utilisateur).

Pour reproduire : exécuter les commandes SSH ci-dessus depuis Core.
