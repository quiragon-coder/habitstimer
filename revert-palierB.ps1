# ==========================
# revert-palierB.ps1 (auto-root)
# ==========================
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
function Write-Title($t) { Write-Host "==> $t" -ForegroundColor Cyan }

function Restore-IfExists($original, $backup) {
  if (Test-Path $backup) {
    Copy-Item $backup $original -Force
    Write-Host "Restauré: $original (depuis $backup)"
  } else {
    Write-Host "Pas de sauvegarde: $backup" -ForegroundColor Yellow
  }
}

if (-not (Test-Path "pubspec.yaml")) { Write-Error "pubspec.yaml introuvable. Place ce script à la racine du projet." }

Write-Title "Restauration des .bak"
Restore-IfExists "pubspec.yaml" "pubspec.yaml.bak"
Restore-IfExists "lib/services/database_service.dart" "lib/services/database_service.dart.bak"
Restore-IfExists "lib/pages/activity_detail_page.dart" "lib/pages/activity_detail_page.dart.bak"

Write-Title "Suppression des fichiers ajoutés (Palier B)"
$added = @(
  "lib/models/stats.dart",
  "lib/providers_stats.dart",
  "lib/widgets/hourly_bars_chart.dart",
  "lib/widgets/weekly_bars_chart.dart",
  "lib/widgets/activity_stats_panel.dart"
)
foreach ($f in $added) { if (Test-Path $f) { Remove-Item $f -Force; Write-Host "Supprimé: $f" } }

Write-Title "flutter pub get"
try { flutter pub get | Write-Host } catch { Write-Host "Lance 'flutter pub get' manuellement si besoin." -ForegroundColor Yellow }

Write-Host "`n✅ Restauration terminée." -ForegroundColor Green
