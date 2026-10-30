# diagnostic.ps1 — Diagnostic AD/DNS pour TwisterLab
# Lecture seule. Ne modifie rien.
# Usage : .\diagnostic.ps1 [-DC <DC-IP>] [-Domain <domain>] [-DCHostname <dc-hostname>]

param(
    [string]$DC = "<DC-IP>",
    [string]$Domain = "<domain>",
    [string]$DCHostname = "<dc-hostname>"
)

# Validation des parametres — empecher l'execution avec des valeurs invalides
if ([string]::IsNullOrWhiteSpace($DC)) {
    Write-Host "ERREUR : le parametre -DC est vide, nul ou ne contient que des espaces. Fournir une valeur reelle." -ForegroundColor Red
    exit 1
}
if ($DC -match [regex]::Escape("<DC-IP>") -or $DC -match [regex]::Escape("<domain>") -or $DC -match [regex]::Escape("<dc-hostname>")) {
    Write-Host "ERREUR : le parametre -DC contient un placeholder ('<DC-IP>', '<domain>' ou '<dc-hostname>'). Fournir une valeur reelle." -ForegroundColor Red
    exit 1
}
if ([string]::IsNullOrWhiteSpace($Domain)) {
    Write-Host "ERREUR : le parametre -Domain est vide, nul ou ne contient que des espaces. Fournir une valeur reelle." -ForegroundColor Red
    exit 1
}
if ($Domain -match [regex]::Escape("<DC-IP>") -or $Domain -match [regex]::Escape("<domain>") -or $Domain -match [regex]::Escape("<dc-hostname>")) {
    Write-Host "ERREUR : le parametre -Domain contient un placeholder ('<DC-IP>', '<domain>' ou '<dc-hostname>'). Fournir une valeur reelle." -ForegroundColor Red
    exit 1
}
if ([string]::IsNullOrWhiteSpace($DCHostname)) {
    Write-Host "ERREUR : le parametre -DCHostname est vide, nul ou ne contient que des espaces. Fournir une valeur reelle." -ForegroundColor Red
    exit 1
}
if ($DCHostname -match [regex]::Escape("<DC-IP>") -or $DCHostname -match [regex]::Escape("<domain>") -or $DCHostname -match [regex]::Escape("<dc-hostname>")) {
    Write-Host "ERREUR : le parametre -DCHostname contient un placeholder ('<DC-IP>', '<domain>' ou '<dc-hostname>'). Fournir une valeur reelle." -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Continue"
$script:results = @()

function Test-Step {
    param([string]$Name, [scriptblock]$Block)
    try {
        $output = & $Block 2>&1
        $status = "OK"
        $detail = ($output | Out-String).Trim()
    } catch {
        $status = "FAIL"
        $detail = $_.Exception.Message
    }
    $script:results += [PSCustomObject]@{ Step = $Name; Status = $status; Detail = $detail }
    Write-Host "[$status] $Name" -ForegroundColor $(if ($status -eq "OK") { "Green" } else { "Red" })
    if ($detail) { Write-Host "  $detail" -ForegroundColor Gray }
}

# 1. Resolution DNS
Test-Step "Resolve $Domain" {
    Resolve-DnsName $Domain -Type A -ErrorAction Stop | Select-Object -ExpandProperty IPAddress
}

Test-Step "Resolve $DCHostname.$Domain" {
    Resolve-DnsName "$DCHostname.$Domain" -Type A -ErrorAction Stop | Select-Object -ExpandProperty IPAddress
}

Test-Step "SRV _ldap._tcp.dc._msdcs.$Domain" {
    Resolve-DnsName "_ldap._tcp.dc._msdcs.$Domain" -Type SRV -ErrorAction Stop | ForEach-Object { "$($_.NameTarget):$($_.Port)" }
}

# 2. Connectivite reseau
Test-Step "Port 53 (DNS) sur $DC" {
    $t = Test-NetConnection -ComputerName $DC -Port 53 -WarningAction SilentlyContinue
    if ($t.TcpTestSucceeded) { "Ouvert" } else { throw "Ferme" }
}

Test-Step "Port 389 (LDAP) sur $DC" {
    $t = Test-NetConnection -ComputerName $DC -Port 389 -WarningAction SilentlyContinue
    if ($t.TcpTestSucceeded) { "Ouvert" } else { throw "Ferme" }
}

Test-Step "Port 636 (LDAPS) sur $DC" {
    $t = Test-NetConnection -ComputerName $DC -Port 636 -WarningAction SilentlyContinue
    if ($t.TcpTestSucceeded) { "Ouvert" } else { throw "Ferme" }
}

# 3. Etat du DC (via WinRM)
Test-Step "NTDS service sur $DC" {
    $cred = Get-Credential -Message "Credentials du contrôleur de domaine" -ErrorAction Stop
    $svc = Invoke-Command -ComputerName $DC -Credential $cred -ScriptBlock {
        (Get-Service NTDS).Status
    } -ErrorAction Stop
    if ($svc -eq "Running") { "Running" } else { throw "Status: $svc" }
}

# 4. Resume
Write-Host "`n=== RESUME ===" -ForegroundColor Cyan
$script:results | Format-Table -AutoSize
$ok = ($script:results | Where-Object { $_.Status -eq "OK" }).Count
$fail = ($script:results | Where-Object { $_.Status -eq "FAIL" }).Count
Write-Output "Total: $($script:results.Count) tests, $ok OK, $fail FAIL"
if ($fail -eq 0) { Write-Host "Tous les tests passent." -ForegroundColor Green } else { Write-Host "Des echecs ont ete detectes." -ForegroundColor Red }
