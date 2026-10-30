# Portfolio — TwisterLab

## Tableau de statut global

| Cas d'usage | Niveau de validation | Tests | Statut |
|---|---|---|---|
| Audit ITSM | Niveau 1 (revue statique) | 34 | `PRÉPARÉ — VALIDATION TECHNIQUE INCOMPLÈTE` |
| Orchestration d'agents (A2A) | Niveau 2 (démontré) | — | `DÉMONTRÉ` |
| Helpdesk IA | Niveau 2 (démontré) | 32 | `DÉMONTRÉ` (scénarios synthétiques) |
| AIOps | Niveau 2 (démontré) | 47 | `DÉMONTRÉ` (1 scénario réel) |

### Clarification des vérifications

| Catégorie | Résultat | Détail |
|---|---|---|
| Tests logiciels | 113 (rapporté) | Tests unitaires avec mocks (ITSM: 34, Helpdesk: 32, AIOps: 47) — ventilation rapportée, non réexécutée dans les phases A.15.x |
| Critères du vérificateur | 14 (rapporté) | Vérification de cohérence structurelle (pas de validation sémantique indépendante) — non revalidés dans cette phase |
| Vérifications syntaxiques | 7 (rapporté) | `bash -n` sur 7 scripts — non re-exécutées dans cette phase |

**Note :** Les 113 tests logiciels, les 14 critères du vérificateur et les 7 vérifications syntaxiques sont des contrôles complémentaires mais distincts. Les tests adversariaux ont produit les échecs attendus (résultat positif). Le vérificateur est un outil de validation de structure, pas de validation sémantique.

## Problème technique traité (ITSM)

La plateforme TwisterITSM est déployée sur Edge (Ubuntu 24.04.5, K3s) depuis plusieurs mois. Elle comprend des APIs .NET (K3s pods), une base PostgreSQL, une base SQL Server, un cache Redis, des ingresses Traefik, et des secrets Kubernetes. L'objectif est de retirer proprement le déploiement ITSM pour libérer des ressources, tout en préservant TwisterLab et les autres projets qui partagent la même infrastructure.

## Architecture et périmètre

### Infrastructure

| Composant | Détail |
|---|---|
| Hôte | Edge — Ubuntu 24.04.5 LTS (i5-6600K, 15 Go RAM) |
| Orchestrateur | K3s v1.33.6 (single node) |
| Conteneurs Docker | itsm-postgres (PostgreSQL 16), itsm-redis (Redis 7) |
| Namespaces K3s | twisteritsm, twisteritsm-ent, twisteritsm-ent-v2, twisteritsm-v2 |
| Bases de données | PostgreSQL (itsm, itsm_v2), SQL Server (TwisterITSM) |
| Sécurité | Secret Entra ID (40 bytes, perms 600), secrets Kubernetes |

### Ressources partagées (NE PAS SUPPRIMER)

| Ressource | Type | Raison |
|---|---|---|
| `mssql` pod (SQL Server) | K3s deployment | Peut être utilisé par d'autres services |
| `twisterlab-itsm-webhook` (port 8000) | K3s service (namespace twisterlab) | Service mort (pas d'endpoints), dépendances non établies |
| `instaswap_directus` (port 8055) | Docker conteneur | Projet instaswap-auth, PAS ITSM |
| K3s cluster, Docker engine, réseau Tailscale | Infrastructure partagée | Partagés avec TwisterLab |

## Choix techniques

1. **Audit en lecture seule d'abord** : aucun arrêt, suppression ou modification avant validation complète
2. **Séparation diagnostic/remédiation** : les scripts de diagnostic sont en lecture seule, les opérations d'écriture nécessitent une approbation
3. **Scripts atomiques** : écriture dans des fichiers temporaires, renommage seulement si succès
4. **Secrets opt-in** : l'export des Secrets K3s est désactivé par défaut
5. **Tests automatisés** : tests unitaires avec mocks pour valider le comportement des scripts sans toucher à l'infrastructure

## Contrôles de sécurité

- **Pas de secrets codés en dur** : mots de passe injectés via variables d'env ou générés aléatoirement
- **Permissions restrictives** : `chmod 700` sur les répertoires, `chmod 600` sur les fichiers
- **Écriture atomique** : `mv -n` (no-clobber) pour éviter l'écrasement
- **Nettoyage garanti** : `trap cleanup EXIT` pour les conteneurs temporaires
- **Secrets opt-in** : export des Secrets K3s désactivé par défaut (`--include-secrets`)
- **Expurgation** : aucune IP, secret ou détail sensible dans les documents publics

## R7 — Inspection des dépendances (lecture seule)

### Résultats

| Composant | Statut | Détail |
|---|---|---|
| SQL Server (mssql pod) | `NON VÉRIFIÉ` | Pod running, ClusterIP service (port 1433), PVC bound (8Gi). Secrets: mssql-secret, ent-api-secrets, ent-db, ent-tls. Aucune référence depuis d'autres services confirmée, mais pas de preuve d'absence. |
| Webhook (twisterlab-itsm-webhook) | `NON VÉRIFIÉ` | Service ClusterIP (port 8000), **aucun endpoint** (service mort). Selector: app=twisterlab, component=api, ha=true. Aucun pod ne correspond. Des clients peuvent encore tenter de l'appeler. |
| Secret Entra ID (fichier) | `NON VÉRIFIÉ` | `/home/twister/.secrets/entra-twisteritsm-secret` (40 bytes, perms 600). Référencé uniquement dans `enable-entra-oidc.sh` (rebuild repo). **Non utilisé par les déploiements actifs.** |
| Secret Entra ID (K8s) | `NON VÉRIFIÉ` | `ent-entra-secrets-v2` dans `twisteritsm-ent-v2` (3 clés: tenant-id, client-id, client-secret). **Activement utilisé par `ent-api` dans `twisteritsm-ent-v2`.** |
| Fichier Compose Windows | `NON VÉRIFIÉ` | Référencé dans les labels Docker (`C:\Users\Administrator\itsm-platform\infra\docker-compose.yml`). **Fichier non trouvé sur Core.** |

### Conclusion R7

- L'Entra ID est activement utilisé par `ent-api` dans `twisteritsm-ent-v2` (via le secret K8s `ent-entra-secrets-v2`)
- Le secret fichier (`entra-twisteritsm-secret`) n'est utilisé que par le projet de rebuild
- Le webhook est mort (pas d'endpoints) mais ses dépendances ne sont pas établies
- SQL Server est isolé (ClusterIP) mais ses dépendances ne sont pas confirmées
- Le fichier Compose Windows n'existe pas sur Core

---

## Stratégie de sauvegarde et de restauration

### Sauvegardes existantes

| Backup | Emplacement | Taille | Date | Statut |
|---|---|---|---|---|
| `master.bak` | `/home/twister/twisteritsm-rebuild/phase0-backup/mssql/` | 4.3 MB | 2026-08-07 | Présent, non testé |
| `TwisterITSM.bak` | `/home/twister/twisteritsm-rebuild/phase0-backup/mssql/` | 11.6 MB | 2026-08-07 | Présent, non testé |
| Backup PostgreSQL | Aucun | N/A | N/A | Manquant |
| Backup K3s manifests | Aucun | N/A | N/A | Manquant |

### Scripts de sauvegarde

| Script | Description | Tests |
|---|---|---|
| `backup-postgres.sh` | Sauvegarde PostgreSQL (itsm, itsm_v2) | 6 tests |
| `restore-postgres-test.sh` | Test de restauration PostgreSQL isolé | Code check |
| `restore-mssql-test.sh` | Test de restauration MSSQL isolé | Code check |
| `export-k3s-manifests.sh` | Export atomique des manifests K3s | 9 tests |

## Tests réalisés et résultats

### Tests exécutés

| Test | Résultat | Détail |
|---|---|---|
| `test-backup-postgres.sh` | ✅ 6/6 PASS | Validation des entrées, création de fichiers, permissions, absence de secrets |
| `test-export-k3s.sh` | ✅ 9/9 PASS | Export par défaut, création de manifests, flag --include-secrets, arguments |
| `test-restore-postgres.sh` | ✅ 8/8 PASS | Backup files, ON_ERROR_STOP, trap, pg_isready, version comparison, etc. |
| `test-restore-mssql.sh` | ✅ 11/11 PASS | trap, -b, FILELISTONLY, ONLINE, no hardcoded passwords, etc. |
| `bash -n` (4 scripts) | ✅ 4/4 OK | Syntaxe Bash valide |

**Total : 34 tests PASS, 0 FAIL (code checks) + 4 syntax checks**

### Limites non vérifiées

- **Niveau 2 (tests isolés)** : non atteint — aucune exécution sur l'infrastructure
- **Niveau 3 (restauration réelle)** : non atteint — aucune restauration réelle
- **Niveau 4 (autorisation opérationnelle)** : non atteint — aucune approbation obtenue
- **Dépendances** : webhook, SQL Server, secret Entra ID non vérifiés
- **Backups MSSQL** : présents mais non testés pour restauration
- **Fichier Compose Windows** : existence non confirmée

## Procédure de démonstration

### 1. Vérification syntaxique des scripts

```bash
for f in demos/04-itsm-audit/scripts/*.sh; do
    bash -n "$f" && echo "OK: $f"
done
```

### 2. Exécution des tests unitaires

```bash
bash demos/04-itsm-audit/tests/test-backup-postgres.sh
bash demos/04-itsm-audit/tests/test-export-k3s.sh
```

### 3. Vérification de l'absence de secrets

```bash
grep -rn "password\|token\|secret\|key\|credential" demos/04-itsm-audit/scripts/ | grep -v "PG_PASSWORD\|PG_TEST_PASS\|MSSQL_TEST_PASS\|POSTGRES_PASSWORD\|SECRET\|#"
# Résultat attendu : aucune valeur sensible
```

### 4. Vérification des permissions

```bash
grep -n "chmod 600\|chmod 700" demos/04-itsm-audit/scripts/*.sh
```

## Prochaine action ayant le meilleur rapport valeur/risque

**Inspection en lecture seule des dépendances** (R7) : vérifier les dépendances SQL Server, webhook et secret Entra ID sur Edge. Cette opération est en lecture seule et ne modifie aucune ressource. Elle débloquerait la suite du processus.

## Statut final

`PRÉPARÉ — VALIDATION TECHNIQUE INCOMPLÈTE`

- **Niveau 1 (revue statique)** : Atteint (contrôle statique uniquement)
- **Niveau 2 (tests isolés)** : ❌ Non atteint
- **Niveau 3 (restauration réelle)** : ❌ Non atteint
- **Niveau 4 (autorisation opérationnelle)** : ❌ Non atteint

---

*Ce portfolio est honnête sur ce qui est réellement fonctionnel et ce qui reste à vérifier. Aucune restauration réelle n'a été effectuée. Aucune opération destructive n'a été autorisée.*
## Cas d'usage démontrés

### Cas d'usage A — Audit ITSM

- **Emplacement :** `demos/04-itsm-audit/`
- **Contenu :** 4 scripts + 4 tests + README + portfolio
- **Statut :** `PRÉPARÉ — VALIDATION TECHNIQUE INCOMPLÈTE`

### Cas d'usage B — Orchestration d'agents (Hermes A2A)

- **Emplacement :** `portfolio/agent-flow.md`
- **Contenu :** Démonstration du flux mission → agent → exécution → preuves → vérification
- **Statut :** `DÉMONTRÉ`

### Cas d'usage C — Helpdesk IA

- **Emplacement :** `portfolio/use-cases/helpdesk-ai/`
- **Contenu :** Ticket synthétique + diagnostic structuré + preuves + procédure de reproduction
- **Statut :** `DÉMONTRÉ`

### Cas d'usage D — AIOps : Diagnostic d'un service indisponible (nouveau)

- **Emplacement :** `portfolio/use-cases/aiops-diagnostics/`
- **Contenu :** Incident synthétique + diagnostic structuré + 21 tests schéma + 8 tests failure modes
- **Statut :** `DÉMONTRÉ`
