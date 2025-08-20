# ==========================
# maintain.ps1
# ==========================
# Utilisation :
#   .\maintain.ps1 -Message "feat: stats panel" -RunTests
#   .\maintain.ps1                 # message auto "chore: maintenance ..."
#   .\maintain.ps1 -SkipAnalyze    # saute 'flutter analyze'

param(
  [string]$Message,
  [switch]$RunTests,
  [switch]$SkipAnalyze
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Title($t){ Write-Host "`n==> $t" -ForegroundColor Cyan }
function Ok($t){ Write-Host "OK: $t" -ForegroundColor Green }
function Warn($t){ Write-Host "WARN: $t" -ForegroundColor Yellow }

# --- Vérifs rapides
if (-not (Test-Path "pubspec.yaml")) { throw "pubspec.yaml introuvable. Place ce script à la racine du projet Flutter." }

# outils dispos ?
foreach ($tool in @("flutter","git")) {
  if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
    throw "$tool n'est pas accessible dans le PATH."
  }
}

# --- Flutter maintenance
Title "Flutter clean"
flutter clean | Write-Host

Title "Flutter pub get"
flutter pub get | Write-Host

if (-not $SkipAnalyze) {
  Title "Flutter analyze"
  flutter analyze
}

if ($RunTests) {
  Title "Flutter test"
  flutter test
}

# --- Git: add / commit / pull --rebase / push
Title "Git status"
git status --porcelain=v1 | Write-Host

# Détection branche courante
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ([string]::IsNullOrWhiteSpace($branch)) { throw "Impossible de détecter la branche git courante." }
Write-Host "Branche: $branch"

# Commit seulement s'il y a des changements
$changes = git status --porcelain
if (-not [string]::IsNullOrWhiteSpace($changes)) {
  Title "Git add"
  git add -A

  if ([string]::IsNullOrWhiteSpace($Message)) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $Message = "chore: maintenance ($timestamp)"
  }

  Title "Git commit"
  git commit -m $Message | Write-Host
} else {
  Warn "Aucun changement à committer."
}

# Pull --rebase avant push (récupère du remote proprement)
Title "Git pull --rebase"
git pull --rebase

# Push
Title "Git push"
git push

Ok "Terminé. Projet synchronisé avec GitHub."
