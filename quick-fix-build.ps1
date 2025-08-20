# ==========================
# quick-fix-build.ps1
# (Débloque la compilation : corrige imports, retire injections DB en doublon,
#  remplace providers_stats par stub temporaire, fixe ActivityDetailPage)
# ==========================
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
function Title($t){ Write-Host "==> $t" -ForegroundColor Cyan }

if (-not (Test-Path "pubspec.yaml")) { Write-Error "Lance ce script depuis la racine du projet (pubspec.yaml introuvable)." }

# 1) Trouver le nom réel du package
Title "Lecture du nom du package"
$pub = Get-Content "pubspec.yaml" -Raw
$pkgMatch = [regex]::Match($pub, "(?m)^\s*name\s*:\s*([a-zA-Z0-9_\-]+)\s*$")
if (-not $pkgMatch.Success) { Write-Error "Impossible de détecter 'name:' dans pubspec.yaml" }
$pkg = $pkgMatch.Groups[1].Value
Write-Host "Package détecté: $pkg"

# 2) Corriger TOUS les imports 'package:habitstimer/...' -> 'package:$pkg/...'
Title "Correction des imports (habitstimer -> $pkg) dans lib/**/*.dart"
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Include *.dart
foreach ($f in $dartFiles) {
  $c = Get-Content $f.FullName -Raw
  if ($c -match "package:habitstimer/") {
    Copy-Item $f.FullName "$($f.FullName).bak_quickfix" -Force
    $c = $c -replace "package:habitstimer/", "package:$pkg/"
    Set-Content $f.FullName $c
    Write-Host "Fix imports: $($f.FullName)"
  }
}

# 3) Nettoyer les injections Palier B dans DatabaseService (toutes occurrences)
$svcPath = "lib/services/database_service.dart"
if (Test-Path $svcPath) {
  Title "Nettoyage des blocs stats dans $svcPath"
  $svc = Get-Content $svcPath -Raw
  Copy-Item $svcPath "$svcPath.bak_quickfix" -Force

  # a) Supprimer nos blocs marqués
  $patternBlock = "(?s)//\s*===\s*Stats helpers ajoutés par Palier B\s*===.*?//\s*===\s*Fin helpers Palier B\s*==="
  $svc = [regex]::Replace($svc, $patternBlock, "")

  # b) Supprimer les fonctions éventuellement dupliquées (même sans marqueurs)
  $dupeFuncs = @(
    "Future<int>\s+minutesForActivityOnDay\s*\(",
    "Future<List<DailyStat>>\s+last7DaysStats\s*\(",
    "Future<List<HourlyBucket>>\s+hourlyDistribution\s*\(",
    "DateTime\s+_startOfDay\s*\(",
    "Duration\s+_effectiveInRange\s*\("
  )
  foreach ($pat in $dupeFuncs) {
    while(([regex]::Matches($svc, $pat)).Count -gt 0) {
      # Retire naïvement jusqu'à la prochaine accolade fermante '}' sur la même profondeur
      # (approximation suffisante ici : on retire bloc par bloc)
      $svc = [regex]::Replace($svc, "(?s)$pat.*?\n\}", "", 1)
    }
  }

  # c) Retirer import stats.dart si présent
  $svc = $svc -replace "^\s*import\s+'package:$([regex]::Escape($pkg))/models/stats\.dart';\s*\r?\n", ""

  # d) S'assurer que le fichier se termine par '}' (si on a retiré la dernière par erreur)
  if (-not $svc.TrimEnd().EndsWith("}")) {
    # On n'essaie pas de deviner la structure exacte; on ajoute pas d'accolade.
    # On laisse l'état précédent : si l'accolade de fin a sauté, on restaure backup.
    # Mais on va vérifier rapidement l'équilibre.
    $opens = ($svc.ToCharArray() | Where-Object { $_ -eq "{" }).Count
    $closes = ($svc.ToCharArray() | Where-Object { $_ -eq "}" }).Count
    if ($opens -gt $closes) {
      # ajoute les '}' manquantes
      $missing = $opens - $closes
      $svc = $svc + ("`n" + ("}" * $missing))
      Write-Host "Ajustement d'accolades: +$missing"
    }
  }

  Set-Content $svcPath $svc
  Write-Host "Blocs stats retirés de database_service.dart"
} else {
  Write-Host "Alerte: $svcPath introuvable — étape ignorée" -ForegroundColor Yellow
}

# 4) Remplacer providers_stats.dart par un STUB temporaire (zéro warning/erreur)
Title "Remplacement de lib/providers_stats.dart par un stub"
$providersPath = "lib/providers_stats.dart"
$providersStub = @"
import 'package:flutter_riverpod/flutter_riverpod.dart';

// STUB de stats provisoire : renvoie des valeurs neutres pour débloquer la compilation.
// On reconnectera aux vraies données DB ensuite, proprement.

class DailyStat {
  final DateTime day;
  final int minutes;
  const DailyStat({required this.day, required this.minutes});
}

class HourlyBucket {
  final int hour;
  final int minutes;
  const HourlyBucket({required this.hour, required this.minutes});
}

final statsTodayProvider = FutureProvider.family<int, String>((ref, activityId) async {
  return 0;
});

final statsLast7DaysProvider = FutureProvider.family<List<DailyStat>, String>((ref, activityId) async {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
  return List.generate(7, (i) {
    final d = DateTime(start.year, start.month, start.day).add(Duration(days: i));
    return DailyStat(day: d, minutes: 0);
  });
});

final hourlyTodayProvider = FutureProvider.family<List<HourlyBucket>, String>((ref, activityId) async {
  return List.generate(24, (h) => HourlyBucket(hour: h, minutes: 0));
});
"@
if (Test-Path $providersPath) { Copy-Item $providersPath "$providersPath.bak_quickfix" -Force }
Set-Content $providersPath $providersStub
Write-Host "Stub écrit: $providersPath"

# 5) Adapter les widgets pour utiliser ces classes locales si besoin (leurs imports pointent vers $pkg/models/stats.dart)
#    Ici on remplace les imports stats par rien, et on redéclare des typedef simples si besoin.
function Fix-WidgetStatsImport($filePath, $typeDefText) {
  if (Test-Path $filePath) {
    $c = Get-Content $filePath -Raw
    $orig = $c
    # Retire l'import vers models/stats.dart
    $c = $c -replace "^\s*import\s+'package:$([regex]::Escape($pkg))/models/stats\.dart';\s*\r?\n", ""
    # Si les types ne sont pas définis dans le fichier, injecter une petite def locale
    if ($c -notmatch "class\s+DailyStat" -and $c -notmatch "class\s+HourlyBucket") {
      $c = $c -replace "(?ms)(class\s+.+)", "$typeDefText`n`n`$1"
    }
    if ($c -ne $orig) {
      Copy-Item $filePath "$filePath.bak_quickfix" -Force
      Set-Content $filePath $c
      Write-Host "Imports stats adaptés: $filePath"
    }
  }
}

$miniTypes = @"
class DailyStat {
  final DateTime day;
  final int minutes;
  const DailyStat({required this.day, required this.minutes});
}
class HourlyBucket {
  final int hour;
  final int minutes;
  const HourlyBucket({required this.hour, required this.minutes});
}
"@

Title "Adaptation des widgets graphiques"
Fix-WidgetStatsImport "lib/widgets/hourly_bars_chart.dart" $miniTypes
Fix-WidgetStatsImport "lib/widgets/weekly_bars_chart.dart" $miniTypes

# 6) Corriger ActivityStatsPanel import + il se base sur providers_stats (stub)
$panelPath = "lib/widgets/activity_stats_panel.dart"
if (Test-Path $panelPath) {
  Title "Adaptation ActivityStatsPanel"
  $p = Get-Content $panelPath -Raw
  Copy-Item $panelPath "$panelPath.bak_quickfix" -Force
  # corriger import vers providers_stats (nom de package inutile ici car fichier local)
  $p = $p -replace "import\s+'package:$([regex]::Escape($pkg))/providers_stats\.dart';", "import 'package:$pkg/providers_stats.dart';"
  # si l'import n'existe pas, en ajouter un
  if ($p -notmatch "providers_stats\.dart") {
    $p = $p -replace "(?ms)(^import\s+'.+?';)", "`$1`nimport 'package:$pkg/providers_stats.dart';"
  }
  Set-Content $panelPath $p
  Write-Host "ActivityStatsPanel relié au stub providers_stats."
} else {
  Write-Host "Attention: $panelPath introuvable." -ForegroundColor Yellow
}

# 7) Fix ActivityDetailPage: importer ActivityStatsPanel et utiliser widget.activity
$pagePath = "lib/pages/activity_detail_page.dart"
if (Test-Path $pagePath) {
  Title "Correction ActivityDetailPage"
  $page = Get-Content $pagePath -Raw
  Copy-Item $pagePath "$pagePath.bak_quickfix" -Force

  # Import unique
  if ($page -notmatch "import\s+'package:$([regex]::Escape($pkg))/widgets/activity_stats_panel\.dart';") {
    $page = $page -replace "(?ms)(^import\s+'.+?';)", "`$1`nimport 'package:$pkg/widgets/activity_stats_panel.dart';"
  }
  # Remplacer activity: activity -> widget.activity
  $page = $page -replace "ActivityStatsPanel\s*\(\s*activity\s*:\s*activity\s*\)", "ActivityStatsPanel(activity: widget.activity)"

  Set-Content $pagePath $page
  Write-Host "ActivityDetailPage mise à jour."
} else {
  Write-Host "Attention: $pagePath introuvable." -ForegroundColor Yellow
}

# 8) flutter pub get
Title "flutter pub get"
try { flutter pub get | Write-Host } catch { Write-Host "Exécute 'flutter pub get' manuellement si nécessaire." -ForegroundColor Yellow }

Write-Host "`n✅ Quick-fix terminé. Lance 'flutter run'. Les graphes s'afficheront mais à 0 (stub). Ensuite on branchera les vraies stats proprement dans DatabaseService." -ForegroundColor Green
