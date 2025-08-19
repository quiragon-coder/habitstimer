param(
  [string]$ProjectPath = "C:\Users\Quiragon\Desktop\Habit timer",
  [string]$RemoteUrl   = "https://github.com/quiragon-coder/habitstimer.git"
)

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[ERR]  $m" -ForegroundColor Red }

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProjectPath)) { Err "Dossier introuvable: $ProjectPath"; exit 1 }
Set-Location $ProjectPath

if (-not (Test-Path ".\pubspec.yaml")) { Err "pubspec.yaml introuvable. Place-toi à la racine du projet."; exit 1 }

# 0) Init Git si besoin et configure le remote
try { git rev-parse --is-inside-work-tree | Out-Null } catch { git init | Out-Null }
try { git remote remove origin | Out-Null } catch {}
git remote add origin $RemoteUrl

# 1) Annuler un éventuel rebase en cours
if ((Test-Path ".git\rebase-merge") -or (Test-Path ".git\rebase-apply")) {
  Info "Rebase en cours détecté -> abort"
  git rebase --abort
}

# 2) Créer l'arborescence Actions et un workflow minimal fiable
New-Item -ItemType Directory -Force -Path ".github\workflows" | Out-Null

$yaml = @"
name: Flutter CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Pub get
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Tests
        run: flutter test

      - name: Build debug APK
        run: flutter build apk --debug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: android-apk-debug
          path: build/app/outputs/**/*.apk
"@

Set-Content -LiteralPath ".github\workflows\flutter_ci.yml" -Value $yaml -Encoding UTF8

# 3) Supprimer l'ancien fichier mal placé s'il existe
if (Test-Path ".githubworkflowsflutter_ci.yml") {
  try { git rm -f ".githubworkflowsflutter_ci.yml" } catch { Remove-Item ".githubworkflowsflutter_ci.yml" -Force }
}

# 4) Ajouter et commit les changements locaux (si nécessaire)
git add -A
$diff = git diff --cached --name-only
if (-not [string]::IsNullOrWhiteSpace($diff)) {
  git commit -m "ci: place workflow in .github/workflows and clean repo" | Out-Null
  Ok "Commit enregistré"
} else {
  Warn "Aucun changement à committer"
}

# 5) Sauvegarder l'état courant dans une branche temporaire
$head = (git rev-parse --short HEAD).Trim()
if ([string]::IsNullOrWhiteSpace($head)) { Err "Impossible de lire HEAD"; exit 1 }
Info "Sauvegarde de l'état courant dans la branche temporaire ci-fix"
git branch -f ci-fix $head | Out-Null

# 6) Synchroniser avec le serveur
Info "Fetch origin"
git fetch origin

# 7) Se placer sur main locale ou la créer à partir d'origin/main
$hasLocalMain = $false
try { git rev-parse --verify main | Out-Null; $hasLocalMain = $true } catch {}
if ($hasLocalMain) {
  git checkout main
} else {
  $hasRemoteMain = $false
  try { git rev-parse --verify origin/main | Out-Null; $hasRemoteMain = $true } catch {}
  if ($hasRemoteMain) {
    git checkout -b main --track origin/main
  } else {
    git checkout -b main
  }
}

# 8) Fusionner ci-fix dans main en préférant la version locale
Info "Merge ci-fix -> main (allow-unrelated-histories, strategy ours)"
$mergeOk = $true
try {
  git merge ci-fix --allow-unrelated-histories -X ours -m "merge ci-fix preferring local changes" | Out-Null
} catch {
  $mergeOk = $false
}
if (-not $mergeOk) {
  Warn "Merge a signalé des conflits. On garde la version locale"
  $conflicts = git diff --name-only --diff-filter=U
  foreach ($f in $conflicts) {
    git checkout --ours -- $f
    git add $f
  }
  git commit -m "resolve: keep local version for conflicts" | Out-Null
}

# 9) Push sur GitHub
Info "Push vers origin/main"
try {
  git push -u origin main
  Ok "Push réussi"
} catch {
  Warn "Push refusé, tentative rebase rapide"
  git pull --rebase origin main --allow-unrelated-histories
  $conflicts = git diff --name-only --diff-filter=U
  if ($conflicts) {
    Warn "Conflits pendant rebase, on garde la version locale"
    foreach ($f in $conflicts) {
      git checkout --ours -- $f
      git add $f
    }
    git rebase --continue
  }
  git push -u origin main
  Ok "Push réussi après rebase"
}

# 10) Nettoyage
try { git branch -D ci-fix | Out-Null } catch {}
Ok "Terminé. Le workflow est dans .github/workflows/flutter_ci.yml"
