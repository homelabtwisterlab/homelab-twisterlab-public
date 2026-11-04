# Younes El Fakir — Portfolio Soutien Informatique N1/N2

> **Homelab réel sur 3 machines · Diagnostic reproductible · Preuves vérifiables**

### 🌐 **[Voir la vitrine en ligne →](https://homelabtwisterlab.github.io/homelab-twisterlab-public/)**

---

## En une phrase

Un technicien en soutien informatique qui documente son homelab réel (Windows Server, AD/DNS, Linux, Docker) avec des démonstrations reproductibles, des preuves mesurées et une documentation honnête des limites.

---

## Compétences démontrées

| Compétence | Démonstration | Statut |
|---|---|---|
| Diagnostic AD / DNS | `demos/01-ad-dns/` | Revu statiquement — non exécuté |
| Diagnostic Linux / Docker | `demos/02-linux-docker/` | Revu statiquement — non exécuté |
| Gestion d'incident | `demos/03-incident-validation/` | Revu statiquement — non exécuté |
| Audit ITSM (lecture seule) | `demos/04-itsm-audit/` | ⚠️ Préparé |
| Administration Windows Server | `docs/` | ✅ Documenté |
| Scripts PowerShell / Bash | `scripts/` | Disponibles — validation d'exécution non confirmée |

---

## Structure du dépôt — contenu réellement publié

```
├── index.html              # Vitrine GitHub Pages
├── demos/                  # 4 démonstrations
│   ├── 01-ad-dns/          # Diagnostic AD/DNS (Windows Server)
│   ├── 02-linux-docker/    # Diagnostic Linux/Docker
│   ├── 03-incident-validation/  # README + preuve (evidence/) — Incident → Correction → Validation
│   └── 04-itsm-audit/      # README + preuve (evidence/) — Audit ITSM (lecture seule)
├── docs/                   # Documentation technique — PARTIELLE
│   ├── architecture.md, INFRASTRUCTURE-cleaned-summary.md (résumé générique, rôle du 3e nœud non précisé)
│   ├── decisions/001 à 004, incidents/ (3), optimisation/, veille/, workflows/T-DISK-MONITOR.md
├── scripts/                # Scripts de diagnostic et d'administration — PARTIELS
│   ├── inventory, mesures, monitor_disk, optimisation, veille, planifier, hermes/fix-edge-user-md.sh
├── tests/                  # Tests des scripts publiés
├── skills/homelab-docs/    # Skill de documentation
├── linkedin/               # Brouillons de posts LinkedIn
├── cloudflare/             # Worker gratuit (substitut gratuit de la Function Azure)
├── azure/                  # Functions en variables d'environnement seulement (sans la fonction à topologie codée en dur)
├── diagrams/               # NOTE GÉNÉRIQUE SEULEMENT (README-cleaned.md) — pas de diagramme réel
└── portfolio/              # Dossier portfolio professionnel
```

**Non publié, volontairement :** démo multi-machines SSH, scripts et tests de la démo 04, inventaire mesuré, messagerie AD/mail, recettes d'accès SSH, audits, carte des sauvegardes, guide Keycloak, topologie réelle et diagramme réel, configuration non revue. Ces éléments restent dans le dépôt privé, qui reste privé.

---

## Principes

1. **Lecture seule** — les scripts ne modifient rien sur les serveurs
2. **Reproductible** — chaque commande est documentée ; exécution non confirmée dans cette phase
3. **Expurgé** — les données sensibles identifiées sont masquées ; vérification complète à effectuer avant publication
4. **Honnête** — les limites et les non-vérifiés sont documentés

---

## Liens

- [Dépôt GitHub](https://github.com/homelabtwisterlab/homelab-twisterlab-public)
- [Démonstrations](https://github.com/homelabtwisterlab/homelab-twisterlab-public/tree/main/demos)
- [Vitrine en ligne](https://homelabtwisterlab.github.io/homelab-twisterlab-public/)
- [LinkedIn](https://www.linkedin.com/in/younes-el-fakir)

---

*Portfolio technique — Soutien informatique N1/N2. Les démonstrations sont basées sur un homelab réel. Les preuves sont expurgées (IPs, secrets, noms de domaine masqués).*
