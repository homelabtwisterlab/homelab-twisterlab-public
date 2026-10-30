# Démo 01 — Diagnostic AD / DNS (Windows Server)

## Objectif

Démontrer la capacité à diagnostiquer un contrôleur de domaine Active Directory
et son service DNS, avec des commandes reproductibles et des résultats mesurables.

## Prérequis

- Accès WinRM au contrôleur de domaine depuis Core
- Credentials : `<domain>\<admin-account>` (mot de passe non publié)
- PowerShell 5.1+ sur Core
- Module ActiveDirectory installé sur le contrôleur de domaine

## Environnement cible

| Élément | Valeur |
|---|---|
| DC | Contrôleur de domaine — Windows Server 2025 |
| Domaine | <domain> |
| DNS | Intégré à AD (zone primaire) |
| LDAP | Port 389 (signing requis par WS 2025) |
| LDAPS | Port 636 (certificat auto-signé) |

> **Note sur l'expurgation** : Les adresses IP LAN/Tailscale, le nom de domaine interne et les noms de comptes sont remplacés par des placeholders dans cette version publique. Les valeurs réelles sont documentées dans la documentation privée (INFRASTRUCTURE.md).

## Commandes de diagnostic

### 1. Vérifier la résolution DNS

```powershell
# Depuis Core (ou tout client du domaine)
Resolve-DnsName <domain> -Type A
Resolve-DnsName <dc-hostname>.<domain> -Type A
Resolve-DnsName _ldap._tcp.dc._msdcs.<domain> -Type SRV
```

**Résultat attendu** :
```
Name                           Type   TTL   Section    IPAddress
----                           ----   ---   -------    ---------
<domain>                       A      600   Answer     <DC-IP>
<dc-hostname>.<domain>               A      1200  Answer     <DC-IP>
_ldap._tcp.dc._msdcs...        SRV    600   Answer     0 100 389 <dc-hostname>.<domain>
```

### 2. Vérifier la connectivité LDAP (test de port, sans authentification)

```powershell
# Test de connectivité TCP au port LDAP — ne transmet pas d'identifiants
Test-NetConnection -ComputerName <DC-IP> -Port 389
Test-NetConnection -ComputerName <DC-IP> -Port 636
```

> **Sécurité** : La démo utilise un test de connectivité sans authentification (`Test-NetConnection`). Un bind LDAP authentifié nécessite LDAPS (port 636) et n'est pas démontré ici pour éviter toute exposition de credentials. Voir `docs/runbook.md` pour la procédure d'authentification sécurisée.

### 3. Vérifier les enregistrements SRV

```powershell
# Depuis Core
Resolve-DnsName _kerberos._tcp.<domain> -Type SRV
Resolve-DnsName _kpasswd._tcp.<domain> -Type SRV
Resolve-DnsName _ldap._tcp.<domain> -Type SRV
```

**Résultat attendu** : chaque SRV pointe vers <dc-hostname>.<domain> avec les ports corrects.

### 4. Vérifier l'état du contrôleur de domaine (via WinRM)

```powershell
# Sur le contrôleur de domaine (via WinRM depuis Core) — lecture seule
Invoke-Command -ComputerName <DC-IP> -Credential $cred -ScriptBlock {
    dcdiag /test:dns /test:connectivity /test:advertising
    nltest /dsgetdc:<domain>
    repadmin /showrepl
}
```

**Résultat attendu** : tous les tests passent, `nltest` retourne le DC, `repadmin` montre 0 erreurs.

### 5. Vérifier la santé du domaine

```powershell
Invoke-Command -ComputerName <DC-IP> -Credential $cred -ScriptBlock {
    Get-ADDomain | Select-Object Name, DomainMode, PDCEmulator, DNSRoot
    Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, IsGlobalCatalog
    (Get-ADUser -Filter *).Count
}
```

**Résultat attendu** : domaine <domain>, 1 DC (contrôleur de domaine), 20+ users.

## Scénario de panne simulée (diagnostic uniquement)

### Symptôme
La résolution DNS échoue pour `<domain>`. Les clients ne peuvent plus se connecter au domaine.

### Hypothèses
1. Service DNS arrêté sur le contrôleur de domaine
2. Zone DNS corrompue ou supprimée
3. Problème réseau (firewall, VLAN)

### Contrôles (lecture seule)
```powershell
# 1. Le service DNS tourne-t-il ?
Get-Service -Name DNS -ComputerName <DC-IP>

# 2. La zone existe-t-elle ?
Get-DnsServerZone -ComputerName <DC-IP>

# 3. Le DC répond-il ?
Test-NetConnection -ComputerName <DC-IP> -Port 53
```

## Remédiation (hors démo — ne pas exécuter sans autorisation)

> **⚠️ Ces commandes modifient l'état du système. Elles sont documentées pour référence mais ne font PAS partie de la démo de diagnostic en lecture seule.**

```powershell
# Redémarrer le service DNS (après vérification qu'aucune tâche n'est en cours)
Restart-Service -Name DNS -ComputerName <DC-IP>

# Réinstaller la zone si corrompue (procédure documentée dans le runbook privé)
# dnscmd /ZoneExport <domain> backup.dns
# ...procédure de restauration...
```

### Preuve de rétablissement (vérification post-remédiation)
```powershell
Resolve-DnsName <domain> -Type A
# → doit retourner <DC-IP>
```

## Limites et risques

- **Ne jamais exécuter `Restart-Service DNS` sans vérifier qu'aucune tâche n'est en cours sur le contrôleur de domaine** (contrainte : 1 tâche à la fois, 8 Go RAM)
- **Ne jamais modifier la zone DNS en production** sans backup (`dnscmd /ZoneExport`)
- **Les tests LDAP authentifiés nécessitent LDAPS (port 636)** — le bind simple sur ldap://389 est refusé par la politique de signature LDAP de WS 2025
- Les résultats sont datés : l'état peut changer entre la mesure et l'exécution

## Résultats réels (mesurés — expurgés)

| Test | Résultat | Date |
|---|---|---|
| Resolve-DnsName <domain> | <DC-IP> ✅ | 2026-10-27 |
| Port 389 (LDAP) | Ouvert ✅ | 2026-10-27 |
| Port 636 (LDAPS) | Ouvert ✅ | 2026-10-27 |
| SRV _ldap._tcp | <dc-hostname>.<domain>:389 ✅ | 2026-10-27 |
| NTDS service | Running ✅ | 2026-10-27 |
| Users AD | 20+ ✅ | 2026-10-27 |

## Preuves (expurgées)

Les captures d'écran et logs sont stockés dans `evidence/` (non committés — contiennent des IPs et des noms d'utilisateur).

Pour reproduire : exécuter les commandes ci-dessus sur Core avec les credentials courants.
