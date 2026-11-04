> **CLEANED COPY — REVIEW BEFORE PUBLISH**
> Source (private, NOT published): `homelabtwisterlab/homelab-twisterlab/docs/incidents/2026-10-24-edge-user-md-limite.md`
> Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

# Incident : mémoire Edge bloquée (USER.md hors limite)

Date : 2026-10-24 | Statut : **Résolu** | Priorité : Moyenne

## 🚩 Symptômes

- L'agent Hermes Edge **ne pouvait plus enregistrer aucun nouveau fait** sur l'utilisateur.
- Aucun message d'erreur visible côté utilisateur : les entrées restaient **lues** mais toute
  **ajout** était rejeté silencieusement.
- Détecté fortuitement en lisant les journaux du gateway Edge pendant un diagnostic sans rapport
  (recherche de la cause d'un `api_server:8642` injoignable).

## 📜 Logs

`journalctl --user -u hermes-gateway.service` (répété à chaque chargement de session) :

```
WARNING tools.memory_tool: USER.md exceeds its char limit on load: 1595/1375 chars.
Entries stay loaded; further additions are blocked until it is back under the limit.
```

## 🔍 Investigation

| Mesure | Valeur |
|---|---|
| `wc -m ~/.hermes/memories/USER.md` | **1643** caractères |
| Limite annoncée par `memory_tool` | **1375** caractères |
| Dépassement | **+268** |
| Permissions du fichier | `644` (lisible par tous) |
| Backups `USER.md.bak.*` | 6 fichiers, également en `644` |

- Hypothèse 1 : limite globale du profil atteinte → **validée** (le message nomme USER.md, et
  `MEMORY.md` à 2110 caractères ne déclenchait rien : la limite est par fichier).
- Hypothèse 2 : fichier verrouillé (`.lock` présent) → **écartée** (`USER.md.lock` fait 0 octet,
  il s'agit d'un verrou vide, non bloquant).

### ⚠️ Constat de sécurité découvert au passage

`USER.md` contenait un **mot de passe en clair** (compte `itsm.admin.test`). Il était donc :

- injecté dans le contexte de **chaque** session de l'agent Edge ;
- présent dans **6 backups** `USER.md.bak.*` en permissions `644` (lisibles par tout compte local).

Cela contredit la doctrine **« Zéro secret »** du lab et consommait du budget de caractères.

## 🎯 Cause racine

Le fichier de mémoire `USER.md` du profil Edge a grandi au-delà de la limite de 1375 caractères.
`memory_tool` applique une politique **fail-closed** sur les ajouts : au-delà de la limite, le
contenu reste chargé (l'agent fonctionne) mais **toute nouvelle écriture est bloquée** — sans
erreur remontée à l'utilisateur.

## ✅ Solution Appliquée

1. **Sauvegarde** horodatée de l'original (`USER.md.bak.<epoch>`).
2. **Extraction du secret** vers `~/.hermes/secrets/itsm-admin-test.txt` (permissions `600`,
   répertoire `700`). La valeur n'est **jamais** passée par le chat ni par un journal.
3. **Durcissement** des 7 backups `USER.md.bak.*` : `644` → `600`.
4. **Réécriture condensée** de `USER.md` : 1643 → **1092** caractères (marge **283**), en
   conservant l'intégralité des faits (identité, mode autonome, règle de preuve, style de réponse,
   livrables « clé en main », règle de statut live, philosophie de design).
5. Permissions de `USER.md` : `644` → **600**.

Script : `scripts/hermes/fix-edge-user-md.sh` (exécuté via `ssh edge`).

## 🛡️ Vérification (Preuve Externe)

Mesurée depuis Core, après application :

| Contrôle | Résultat |
|---|---|
| `wc -m ~/.hermes/memories/USER.md` | **1092** (< 1375) |
| `stat -c %a USER.md` | **600** |
| `grep -c password USER.md` | **0** |
| `~/.hermes/secrets/itsm-admin-test.txt` | présent, `600`, 10 caractères |
| Session Edge réelle (`hermes peer dm edge`) | ✅ a répondu `memoire ok` |
| Journal gateway depuis le correctif | ✅ **aucun** `exceeds its char limit` |

## 💡 Leçon Apprise

**Une limite de mémoire atteinte est une panne silencieuse : l'agent continue de répondre
normalement, mais n'apprend plus rien.** Le seul symptôme est une ligne `WARNING` dans le journal
du gateway — il faut donc la surveiller, ou vérifier `wc -m` sur les fichiers de mémoire après
toute session longue. Corollaire : un fichier de mémoire ne doit **jamais** contenir de secret
(injecté à chaque session, souvent dupliqué dans les backups).
