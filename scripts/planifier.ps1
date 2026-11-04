# CLEANED COPY - REVIEW BEFORE PUBLISH
# Source (private, NOT published): homelabtwisterlab/homelab-twisterlab/scripts/planifier.ps1
# Redactions: real IPs, internal domains, emails and secret assignments replaced with placeholders. Manual review required before any publication.

# Tâche planifiée : exécute la veille et l'optimisation chaque lundi à 08:00
# Installation : schtasks /Create /TN "TwisterLab-Veille" /TR "powershell -File C:\Users\administrator\homelab-twisterlab\scripts\planifier.ps1" /SC WEEKLY /D MON /ST 08:00

$ErrorActionPreference = "Stop"
$root = "C:\Users\administrator\homelab-twisterlab"
Set-Location $root

Write-Output "=== TwisterLab — Veille & Optimisation ==="
Write-Output "Date: $(Get-Date)"

Write-Output "`n--- Veille technologique ---"
python3 scripts/veille.py

Write-Output "`n--- Optimisation ---"
python3 scripts/optimisation.py

Write-Output "`n--- Tests ---"
python3 -m pytest tests/ -v --tb=short

Write-Output "`n=== Terminé ==="
