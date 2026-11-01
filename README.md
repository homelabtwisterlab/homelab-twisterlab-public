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

## Structure du dépôt

```
├── index.html              # Vitrine GitHub Pages
├── demos/                  # 4 démonstrations reproductibles
│   ├── 01-ad-dns/          # Diagnostic AD/DNS (Windows Server)
│   ├── 02-linux-docker/    # Diagnostic Linux/Docker
│   ├── 03-incident-validation/  # Incident → Correction → Validation
│   └── 04-itsm-audit/      # Audit ITSM (lecture seule)
├── docs/                   # Documentation technique
├── scripts/                # Scripts de diagnostic et d'administration
├── diagrams/               # Diagrammes d'architecture
└── portfolio/              # Dossier portfolio professionnel
```

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