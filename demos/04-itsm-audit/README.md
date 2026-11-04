> **CLEANED COPY — REVIEW BEFORE PUBLISH**
> Source (private, NOT published): `homelabtwisterlab/homelab-twisterlab/demos/04-itsm-audit/README.md`
> Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

# Démo 04 — Audit et préparation au retrait contrôlé d'une plateforme ITSM

## Objectif

Démontrer la capacité à auditer une plateforme ITSM déployée sur Kubernetes (K3s)
et Docker, identifier ses dépendances, évaluer les risques et préparer un plan de
retrait contrôlé sans interrompre les services partagés.

Cette démo couvre : inventaire technique, analyse des dépendances, stratégie de
sauvegarde, plan de rollback, et gestion des risques dans un contexte multi-projet.

## Prérequis

- Accès SSH à Edge depuis Core
- `kubectl` configuré sur Edge (K3s)
- `docker` installé et fonctionnel sur Edge
- Compréhension de base de Kubernetes (namespaces, deployments, services, PVC)

## Environnement cible

| Élément | Valeur |
|---|---|
| Hôte | Edge — Ubuntu 24.04.5 LTS |
| Orchestrateur | K3s v1.33.6 (single node) |
| Conteneurs Docker | itsm-postgres (PostgreSQL 16), itsm-redis (Redis 7) |
| Namespaces K3s | twisteritsm, twisteritsm-ent, twisteritsm-ent-v2, twisteritsm-v2 |
| Bases de données | PostgreSQL (itsm, itsm_v2), SQL Server (TwisterITSM) |
| Statut | Audit complété (lecture seule), aucune suppression effectuée |

## Contexte

La plateforme ITSM (TwisterITSM) est déployée sur Edge depuis plusieurs mois.
Elle comprend des APIs .NET (K3s pods), une base PostgreSQL, une base SQL Server,
un cache Redis, des ingresses Traefik, et des secrets Kubernetes.

L'objectif est de retirer proprement le déploiement ITSM pour libérer des ressources,
tout en préservant TwisterLab et les autres projets qui partagent la même infrastructure.

**Aucune suppression n'a été effectuée.** Seul un audit en lecture seule a été réalisé.

## Inventaire technique (mesuré)

### Namespaces K3s

| Namespace | Deployments actifs | Deployments arrêtés | Services | Ingress | Secrets | ConfigMaps |
|---|---|---|---|---|---|---|
| `twisteritsm` | 0 | 3 (itsm-api, itsm-nginx, itsm-web) | 4 | 1 (itsm.<DOMAIN-PLACEHOLDER>) | 2 | 2 |
| `twisteritsm-ent` | 2 (ent-api, mssql) | 3 (ent-web-admin, ent-web-ops, ent-web-portal) | 6 | 0 | 4 | 1 |
| `twisteritsm-ent-v2` | 2 (ent-api, ent-web) | 0 | 2 | 1 (ent.<DOMAIN-PLACEHOLDER>) | 10 (dont 8 Helm) | 1 |
| `twisteritsm-v2` | 0 | 2 (itsm-api, itsm-web) | 2 | 1 (itsm-v2.<DOMAIN-PLACEHOLDER>) | 2 | 1 |

### Conteneurs Docker

| Conteneur | Image | Port | Statut | Projet |
|---|---|---|---|---|
| `itsm-postgres` | postgres:16-alpine | 5433 | Up (healthy) | itsm |
| `itsm-redis` | redis:7-alpine | 6380 | Up | itsm |

### Bases de données

| Moteur | Base | Tables | Données | Statut |
|---|---|---|---|---|
| PostgreSQL 16 | `itsm` | 1 (migrations) | Vide | Vérifié |
| PostgreSQL 16 | `itsm_v2` | 13 | 39 tickets, 10 users, 32 CMDB items | Vérifié |
| SQL Server (K3s pod) | `TwisterITSM` | 25 | Données réelles | Vérifié (backup .bak présent) |

### Ressources partagées identifiées (NE PAS SUPPRIMER)

| Ressource | Type | Raison | Statut |
|---|---|---|---|
| `mssql` pod (SQL Server) | K3s deployment | Peut être utilisé par d'autres services | Bloqué — dépendances non établies |
| `twisterlab-itsm-webhook` (port 8000) | K3s service (namespace twisterlab) | Aucun pod ne correspond au selector (service mort) | Bloqué — dépendances non établies |
| `instaswap_directus` (port 8055) | Docker conteneur | Projet instaswap-auth, PAS ITSM | Vérifié — ne pas toucher |
| K3s cluster (kube-system, argocd, cert-manager) | Infrastructure partagée | Infrastructure partagée | Vérifié — ne pas toucher |
| Docker engine | Infrastructure partagée | Infrastructure partagée | Vérifié — ne pas toucher |
| Réseau Tailscale | Infrastructure partagée | Infrastructure partagée | Vérifié — ne pas toucher |

### Webhook `twisterlab-itsm-webhook` (analyse)

Le service `twisterlab-itsm-webhook` dans le namespace `twisterlab` a un selector
`app=twisterlab, component=api, ha=true`. Aucun pod ne correspond à ce selector
(service mort — pas d'endpoints). Cela ne prouve pas que sa configuration ou son
code peut être supprimé sans conséquence.

**Statut : `BLOQUÉ` — dépendances non établies.**

### Secret Entra ID

Le fichier `/home/<USER>/.secrets/entra-twisteritsm-secret` (40 bytes, perms 600)
contient un secret Entra ID pour l'App Registration ITSM. Il est référencé
uniquement dans `/home/<USER>/twisteritsm-rebuild/repo/infra/scripts/enable-entra-oidc.sh`.

**Statut : `BLOQUÉ` — dépendances non établies. La révocation est une opération distincte.**

## Procédure d'audit (lecture seule)

### 1. Inventaire Kubernetes

```bash
# Pour chaque namespace ITSM :
for ns in twisteritsm twisteritsm-ent twisteritsm-ent-v2 twisteritsm-v2; do
  echo "=== $ns ==="
  kubectl get deploy,svc,ingress,configmap,secret,pvc -n $ns
done
```

**Résultat attendu** : liste complète des ressources par namespace.

### 2. Inventaire Docker

```bash
# Conteneurs ITSM
docker ps -a --filter name=itsm --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'

# Volume ITSM
docker volume inspect itsm_itsm_pgdata

# Réseau ITSM
docker network inspect itsm_default
```

**Résultat attendu** : conteneurs, volume, réseau avec détails.

### 3. Vérification des dépendances

```bash
# Vérifier si le webhook est utilisé
kubectl get svc -n twisterlab twisterlab-itsm-webhook -o yaml | grep -A5 selector

# Vérifier si SQL Server est utilisé par d'autres services
kubectl get svc -A | grep -i sqlserver

# Vérifier les références au secret Entra ID
grep -rl "entra-twisteritsm-secret" /home/<USER>/ 2>/dev/null | head -5
```

**Résultat attendu** : dépendances identifiées ou confirmées absentes.

### 4. Vérification des backups

```bash
# Vérifier les backups MSSQL existants
ls -la /home/<USER>/twisteritsm-rebuild/phase0-backup/mssql/

# Vérifier les backups PostgreSQL (aucun trouvé)
find /home/<USER> -name "*.sql" -o -name "*.dump" 2>/dev/null | grep -i itsm | head -5
```

**Résultat attendu** : backups MSSQL présents, pas de backup PostgreSQL.

## Limites et risques

- **Ne jamais supprimer un namespace entier** avant d'avoir inventorié toutes ses ressources
- **Ne jamais supprimer une base ou un volume** sans backup vérifié
- **Ne jamais supprimer le secret Entra ID** sans vérifier les dépendances
- **Ne jamais supprimer le webhook** sans confirmer qu'il n'est pas utilisé
- **Ne jamais supprimer SQL Server** sans vérifier les dépendances
- **Toujours créer un backup** avant toute suppression
- **Toujours vérifier les autres services** après chaque action

## Résultats réels (mesurés — expurgés)

| Élément | Valeur | Date |
|---|---|---|
| Namespaces ITSM | 4 (twisteritsm, twisteritsm-ent, twisteritsm-ent-v2, twisteritsm-v2) | 2026-10-27 |
| Deployments actifs | 4 (ent-api ×2, ent-web, mssql) | 2026-10-27 |
| Deployments arrêtés | 9 (scaled down 0/0) | 2026-10-27 |
| Conteneurs Docker ITSM | 2 (itsm-postgres, itsm-redis) | 2026-10-27 |
| Bases PostgreSQL | 2 (itsm: 1 table, itsm_v2: 13 tables) | 2026-10-27 |
| Base SQL Server | 1 (TwisterITSM, 25 tables) | 2026-10-27 |
| Secret Entra ID | 1 (40 bytes, perms 600) | 2026-10-27 |
| Backup MSSQL | 2 fichiers (.bak, 4.3MB + 11.6MB) | 2026-10-27 |
| Backup PostgreSQL | 0 | 2026-10-27 |
| Webhook ITSM | 1 service mort (pas d'endpoints) | 2026-10-27 |

## Preuves (expurgées)

Les commandes et résultats sont documentés dans le rapport d'audit ITSM.
Les IPs, noms de domaines et secrets sont remplacés par des placeholders.

Pour reproduire : exécuter les commandes SSH ci-dessus depuis Core avec accès Edge.

## Modèle pour futurs audits d'infrastructure

Cette démo sert de modèle pour auditer tout composant avant retrait :

1. **Inventaire** — lister toutes les ressources (K3s, Docker, fichiers, secrets)
2. **Dépendances** — identifier les ressources partagées et les dépendances
3. **Risques** — évaluer les risques de suppression
4. **Sauvegarde** — préparer les backups avant toute action
5. **Rollback** — définir le plan de retour arrière
6. **Approbation** — obtenir l'approbation explicite avant chaque action destructive
7. **Vérification** — confirmer que les autres services ne sont pas impactés

## Compétences démontrées

| Compétence | Application |
|---|---|
| Kubernetes (K3s) | Inventaire namespaces, deployments, services, ingresses, secrets, PVC/PV |
| Docker | Inventaire conteneurs, volumes, réseaux, compose files |
| PostgreSQL | Inventaire bases, tables, données, connexions |
| SQL Server (MSSQL) | Inventaire bases, backups, dépendances |
| Analyse de dépendances | Identification des ressources partagées et des dépendances |
| Gestion des risques | Évaluation des risques de suppression, plan de rollback |
| Documentation technique | Rapport d'audit professionnel, traçable, expurgé |
| Sécurité | Gestion des secrets, protection des données sensibles |
| Méthode | Audit en lecture seule, préparation avant action, approbation explicite |

---

**Note sur l'expurgation** : Cette démo ne contient pas d'adresses IP, de secrets ou de détails d'infrastructure sensibles. Les noms de services, ports et namespaces sont des détails d'architecture publique. Les valeurs réelles sont documentées dans la documentation privée (INFRASTRUCTURE.md).