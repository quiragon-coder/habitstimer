# tools\push.ps1
param(
  [string]$Message = "chore: update from local"
)

# Arrêt sur erreur
$ErrorActionPreference = "Stop"

function Ensure-GitIdentity {
  $name = git config user.name 2>$null
  $email = git config user.email 2>$null
  if (-not $name)  { git config user.name  "Quiragon" }
  if (-not $email) { git config user.email "you@example.com" }
}

Write-Host "==> 1/4: Nettoyage & dépendances" -ForegroundColor Cyan
flutter clean | Out-Null
flutter pub get | Out-Null

Write-Host "==> 2/4: Vérif rapide (analyze + tests)" -ForegroundColor Cyan
flutter analyze
# Les tests peuvent être lents; enlève cette ligne si tu veux aller plus vite
flutter test -r expanded

Write-Host "==> 3/4: Git add/commit" -ForegroundColor Cyan
Ensure-GitIdentity
git status --porcelain

# S'il n'y a rien à commiter, on sort proprement
if ((git status --porcelain).Length -eq 0) {
  Write-Host "Aucun changement à commiter." -ForegroundColor Yellow
  exit 0
}

git add -A
git commit -m "$Message"

Write-Host "==> 4/4: Push vers origin/main" -ForegroundColor Cyan
# Assure le remote s’il manque
if (-not (git remote 2>$null | Select-String -SimpleMatch "origin")) {
  git remote add origin "https://github.com/quiragon-coder/habitstimer.git"
}

# S’assure d’être sur main
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main") {
  git checkout -B main
}

git push -u origin main

# Affiche l’URL du dernier commit
$sha = (git rev-parse HEAD).Trim()
Write-Host "✅ Poussé: https://github.com/quiragon-coder/habitstimer/commit/$sha" -ForegroundColor Green
