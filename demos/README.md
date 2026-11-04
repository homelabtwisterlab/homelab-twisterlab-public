> **CLEANED COPY — REVIEW BEFORE PUBLISH**
> Source (private, NOT published): `homelabtwisterlab/homelab-twisterlab/demos/README.md`
> Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

# Démos TwisterLab — Preuves de compétences

Ce répertoire contient 4 démonstrations reproductibles basées sur l'infrastructure réelle de TwisterLab.
Chaque démo documente des commandes exactes, des résultats attendus et des preuves mesurées.

## Structure

```
demos/
├── README.md                    # Ce fichier
├── 01-ad-dns/
│   ├── README.md                # Diagnostic AD/DNS (Windows Server)
│   ├── diagnostic.ps1           # Script de diagnostic PowerShell
│   └── evidence/                # Captures et logs (non committés)
├── 02-linux-docker/
│   ├── README.md                # Diagnostic Linux/Docker
│   ├── diagnostic.sh            # Script de diagnostic bash
│   └── evidence/                # Captures et logs (non committés)
├── 03-incident-validation/
│   ├── README.md                # Incident → correction → validation
│   └── evidence/                # Captures et logs (non committés)
└── 04-itsm-audit/
    ├── README.md                # Audit ITSM : inventaire, dépendances, plan de retrait
    └── evidence/                # Captures et logs (non committés)
```

## Principes

1. **Lecture seule** — les scripts ne modifient rien sur les serveurs (la remédiation est documentée séparément, hors démo)
2. **Reproductible** — chaque commande est exacte et testée
3. **Preuve mesurée** — les résultats sont datés et vérifiés
4. **Expurgé** — les README publics remplacent IPs, domaines internes et noms de comptes par des placeholders (`<domain>`, `<DC-IP>`). Les valeurs réelles sont dans la documentation privée (INFRASTRUCTURE.md).
5. **Honnête** — les échecs et les hypothèses non confirmées sont documentés

## Compétences démontrées

| Démo | Compétences | Pertinence CV |
|---|---|---|
| 01 AD/DNS | Windows Server, AD, DNS, SRV, LDAP, diagnostic réseau | Technicien N2, admin junior |
| 02 Linux/Docker | Linux, Docker, diagnostic conteneurs, logs, ressources | Support N2, Linux junior |
| 03 Incident | Analyse de cause racine, correction, validation, post-mortem | Exploitation, gestion incidents |
| 04 ITSM Audit | Inventaire K3s/Docker/DB, dépendances, sauvegarde, rollback, risques | Administration systèmes, DevOps junior |

## Utilisation

Chaque démo est autonome. Lire le README.md pour les prérequis et les commandes.
Les scripts sont en lecture seule et ne modifient rien.

Pour reproduire : exécuter les commandes sur Core (Windows) ou Edge (Linux) avec les credentials appropriés.
