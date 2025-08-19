# push-to-github.ps1
param(
  [string]$ProjectPath = "C:\Users\Quiragon\Desktop\Habit timer",
  [string]$RemoteUrl   = "https://github.com/quiragon-coder/habitstimer.git",
  [string]$BranchName  = "main",
  [string]$CommitMsg   = "feat: initial Flutter project"
)

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[ERREUR] $m" -ForegroundColor Red }

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 0) Vérifs de base
if (-not (Test-Path $ProjectPath)) {
  Write-Err "Le dossier '$ProjectPath' n'existe pas."
  exit 1
}
Set-Location $ProjectPath
Write-Info "Dossier: $(Get-Location)"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Err "Git n'est pas installé ou pas dans le PATH. Installe Git puis relance le script."
  exit 1
}

if (-not (Test-Path ".\pubspec.yaml")) {
  Write-Err "pubspec.yaml introuvable. Assure-toi d'être à la racine du projet Flutter."
  exit 1
}

# 1) .gitignore Flutter
Write-Info "Création/MAJ du .gitignore Flutter"
@"
# --- Flutter / Dart ---
.dart_tool/
.packages
build/
coverage/
pubspec.lock

# --- Android / Gradle ---
android/.gradle/
android/local.properties
**/*.keystore
**/key.properties

# --- iOS / macOS ---
ios/Pods/
macos/Pods/
**/DerivedData/
**/*.xcworkspace/
**/*.xcodeproj/project.xcworkspace/
**/*.xcodeproj/xcuserdata/
**/*.xcuserdatad/

# --- Linux / Windows / Web ephemerals ---
linux/flutter/ephemeral/
windows/flutter/ephemeral/
web/.dart_tool/

# --- IDE ---
.idea/
.vscode/
*.iml

# --- Autres ---
*.log
"@ | Out-File -FilePath .gitignore -Encoding UTF8 -NoNewline
Write-Ok ".gitignore prêt"

# 2) Init repo si besoin
$inside = $false
try {
  git rev-parse --is-inside-work-tree | Out-Null
  $inside = $true
} catch {}

if (-not $inside) {
  Write-Info "Initialisation du dépôt Git"
  git init | Out-Null
  Write-Ok "git init"
} else {
  Write-Ok "Repo Git déjà initialisé"
}

# 3) Config remote propre
Write-Info "Configuration du remote origin"
try { git remote remove origin | Out-Null } catch {}
git remote add origin $RemoteUrl
Write-Ok "origin = $RemoteUrl"

# 4) Ajouter fichiers & commit
Write-Info "Ajout des fichiers au commit"
git add -A

$diff = git diff --cached --name-only
if ([string]::IsNullOrWhiteSpace($diff)) {
  Write-Warn "Rien à committer (peut-être déjà committé)."
} else {
  git commit -m $CommitMsg | Out-Null
  Write-Ok "Commit effectué: $CommitMsg"
}

# 5) Branchement principal
Write-Info "Positionnement sur la branche '$BranchName'"
git branch -M $BranchName
Write-Ok "Branche par défaut: $BranchName"

# 6) Push vers GitHub
Write-Info "Push vers GitHub"
git push -u origin $BranchName
Write-Ok "Push terminé. Va voir sur: $RemoteUrl"
