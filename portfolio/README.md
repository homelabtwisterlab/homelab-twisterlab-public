# Portfolio — Homelab local (vitrine publique)

Vitrine publique du homelab local de Younes El Fakir, technicien en soutien
informatique N1/N2 — Service Desk, support augmenté par l'IA.

Ce portfolio présente des démos de support informatique, pas un projet
d'entreprise. **TwisterLab est un projet d'entreprise distinct, orchestré par
des agents, et n'est pas décrit ici.** Le homelab local et TwisterLab sont deux
projets séparés.

## Démonstrations publiées

| Démo | Sujet | Contenu publié |
|---|---|---|
| 01 | AD / DNS | Procédure et script de diagnostic |
| 02 | Linux / Docker | Procédure et script de diagnostic |
| 03 | Validation d'incident | README et preuve |
| 04 | Audit ITSM | README et échantillon de preuve seulement |

## Tableau de statut global

| Cas d'usage | Statut |
|---|---|
| Audit ITSM | `PRÉPARÉ — VALIDATION TECHNIQUE INCOMPLÈTE` |
| Validation d'incident | Démonstration avec preuve |
| Diagnostic AD / DNS | Démonstration |
| Diagnostic Linux / Docker | Démonstration |

## Procédure de démonstration

> **Note portage 2026-11-03 :** dans ce dépôt public, la démo 04 ne fournit que son README et un échantillon de preuve (`demos/04-itsm-audit/README.md` + `evidence/audit-sample.txt`). Les scripts (`demos/04-itsm-audit/scripts/*.sh`) et tests (`demos/04-itsm-audit/tests/*.sh`) cités dans la procédure d'origine décrivent la procédure d'origine et ne sont pas publiés ici ; ils ne sont donc pas exécutables depuis ce dépôt.

### 1. Vérification syntaxique des scripts

```bash
for f in demos/04-itsm-audit/scripts/*.sh; do
    bash -n "$f" && echo "OK: $f"
done
```

### 2. Exécution des tests unitaires

Les tests unitaires de la procédure d'origine ne sont pas publiés ici ;
ils ne sont donc pas exécutables depuis ce dépôt.

### 3. Vérification de l'absence de secrets

```bash
grep -rn "password\|token\|secret\|key\|credential" demos/04-itsm-audit/scripts/ | grep -v "PG_PASSWORD\|PG_TEST_PASS\|MSSQL_TEST_PASS\|POSTGRES_PASSWORD\|SECRET\|#"
# Résultat attendu : aucune valeur sensible
```

### 4. Vérification des permissions

```bash
grep -n "chmod 600\|chmod 700" demos/04-itsm-audit/scripts/*.sh
```

## Statut final

`PRÉPARÉ — VALIDATION TECHNIQUE INCOMPLÈTE`

- **Niveau 1 (revue statique)** : Atteint (contrôle statique uniquement)
- **Niveau 2 (tests isolés)** : ❌ Non atteint
- **Niveau 3 (restauration réelle)** : ❌ Non atteint
- **Niveau 4 (autorisation opérationnelle)** : ❌ Non atteint

---

*Ce portfolio est honnête sur ce qui est réellement fonctionnel et ce qui reste à vérifier. Aucune restauration réelle n'a été effectuée. Aucune opération destructive n'a été autorisée. Aucune adresse, aucun domaine interne, aucun secret ni détail d'infrastructure n'est publié ici.*
