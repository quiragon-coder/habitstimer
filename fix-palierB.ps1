# ==========================
# fix-palierB.ps1 (auto-root)
# ==========================
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
function Write-Title($t) { Write-Host "==> $t" -ForegroundColor Cyan }

if (-not (Test-Path "pubspec.yaml")) { Write-Error "pubspec.yaml introuvable. Place ce script à la racine du projet." }

# 1) Nom du package réel
Write-Title "Lecture du nom du package"
$pub = Get-Content "pubspec.yaml" -Raw
$pkgMatch = [regex]::Match($pub, "(?m)^\s*name\s*:\s*([a-zA-Z0-9_\-]+)\s*$")
if (-not $pkgMatch.Success) { Write-Error "Impossible de détecter 'name:' dans pubspec.yaml" }
$pkg = $pkgMatch.Groups[1].Value
Write-Host "Package: $pkg"

# 2) Corriger imports habitstimer -> $pkg
Write-Title "Correction des imports package:"
$fixFiles = @(
  "lib/providers_stats.dart",
  "lib/widgets/hourly_bars_chart.dart",
  "lib/widgets/weekly_bars_chart.dart",
  "lib/widgets/activity_stats_panel.dart",
  "lib/pages/activity_detail_page.dart",
  "lib/services/database_service.dart"
) | Where-Object { Test-Path $_ }

foreach ($f in $fixFiles) {
  $c = Get-Content $f -Raw
  $orig = $c
  $c = $c -replace "package:habitstimer/", "package:$pkg/"
  if ($c -ne $orig) { Copy-Item $f "$f.bak_fix" -Force; Set-Content $f $c; Write-Host "Fix imports: $f" }
}

# 3) Nettoyer doublons bloc Palier B dans DatabaseService et réinsérer proprement
$svcPath = "lib/services/database_service.dart"
if (Test-Path $svcPath) {
  Write-Title "Nettoyage bloc Palier B"
  $svc = Get-Content $svcPath -Raw
  $patternBlock = "(?s)//\s*===\s*Stats helpers ajoutés par Palier B\s*===.*?//\s*===\s*Fin helpers Palier B\s*==="
  if ([regex]::IsMatch($svc, $patternBlock)) {
    Copy-Item $svcPath "$svcPath.bak_fix_block" -Force
    $svc = [regex]::Replace($svc, $patternBlock, "")
  }
  $dupe = @("minutesForActivityOnDay\(", "last7DaysStats\(", "hourlyDistribution\(", "_startOfDay\(", "_effectiveInRange\(")
  foreach ($p in $dupe) {
    while(([regex]::Matches($svc, $p)).Count -gt 1) {
      $svc = [regex]::Replace($svc, "(?s)$p.*?\n\}", "", 1)
    }
  }
  if ($svc -notmatch "import\s+'package:$pkg/models/stats.dart';") {
    $svc = $svc -replace "(?ms)(^import\s+'.+?';)", "`$1`nimport 'package:$pkg/models/stats.dart';"
  }
  $methods = @"
// === Stats helpers ajoutés par Palier B ===
DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

Duration _effectiveInRange({
  required DateTime rangeStart,
  required DateTime rangeEnd,
  required DateTime sessionStart,
  required DateTime? sessionEnd,
  required List<(DateTime start, DateTime? end)> pauses,
}) {
  final s = sessionStart.isAfter(rangeStart) ? sessionStart : rangeStart;
  final e = (sessionEnd ?? DateTime.now()).isBefore(rangeEnd)
      ? (sessionEnd ?? DateTime.now())
      : rangeEnd;
  if (!e.isAfter(s)) return Duration.zero;

  var active = e.difference(s);
  for (final p in pauses) {
    final ps = p.$1.isAfter(rangeStart) ? p.$1 : rangeStart;
    final pe = (p.$2 ?? DateTime.now()).isBefore(rangeEnd) ? (p.$2 ?? DateTime.now()) : rangeEnd;
    final overlapStart = ps.isAfter(s) ? ps : s;
    final overlapEnd = pe.isBefore(e) ? pe : e;
    if (overlapEnd.isAfter(overlapStart)) {
      active -= overlapEnd.difference(overlapStart);
    }
  }
  return active.isNegative ? Duration.zero : active;
}

Future<int> minutesForActivityOnDay(String activityId, DateTime day) async {
  final from = _startOfDay(day);
  final to   = _startOfDay(day.add(const Duration(days: 1)));
  final sessions = await getSessionsByActivity(activityId);
  int minutes = 0;
  for (final s in sessions) {
    final pauses = await getPausesBySession(s.id);
    final dur = _effectiveInRange(
      rangeStart: from,
      rangeEnd: to,
      sessionStart: s.startAt,
      sessionEnd: s.endAt,
      pauses: pauses.map((p) => (p.startAt, p.endAt)).toList(),
    );
    minutes += dur.inMinutes;
  }
  return minutes;
}

Future<List<DailyStat>> last7DaysStats(String activityId) async {
  final today = DateTime.now();
  final start = _startOfDay(today.subtract(const Duration(days: 6)));
  final days = List.generate(7, (i) => _startOfDay(start.add(Duration(days: i))));
  final result = <DailyStat>[];
  for (final d in days) {
    final m = await minutesForActivityOnDay(activityId, d);
    result.add(DailyStat(day: d, minutes: m));
  }
  return result;
}

Future<List<HourlyBucket>> hourlyDistribution(String activityId, DateTime day) async {
  final from = _startOfDay(day);
  final to = _startOfDay(day.add(const Duration(days: 1)));
  final buckets = List.generate(24, (h) => HourlyBucket(hour: h, minutes: 0));
  final sessions = await getSessionsByActivity(activityId);

  for (final s in sessions) {
    final pauses = await getPausesBySession(s.id);
    final effStart = s.startAt.isAfter(from) ? s.startAt : from;
    final effEnd = (s.endAt ?? DateTime.now()).isBefore(to) ? (s.endAt ?? DateTime.now()) : to;
    if (!effEnd.isAfter(effStart)) continue;

    for (var t = effStart; t.isBefore(effEnd); t = t.add(const Duration(minutes: 1))) {
      final inPause = pauses.any((p) {
        final ps = p.startAt;
        final pe = p.endAt ?? DateTime.now();
        return !t.isBefore(ps) && t.isBefore(pe);
      });
      if (inPause) continue;
      final h = t.hour;
      buckets[h] = HourlyBucket(hour: h, minutes: buckets[h].minutes + 1);
    }
  }
  return buckets;
}
// === Fin helpers Palier B ===
"
  $last = $svc.LastIndexOf("}")
  if ($last -lt 0) { Write-Error "database_service.dart semble mal formé (accolade de fin manquante)." }
  $svc = $svc.Insert($last, "`n$methods`n")
  Set-Content $svcPath $svc
} else {
  Write-Host "Attention: $svcPath introuvable." -ForegroundColor Yellow
}

# 4) Corriger ActivityDetailPage (widget.activity + import unique)
$pagePath = "lib/pages/activity_detail_page.dart"
if (Test-Path $pagePath) {
  Write-Title "Correction ActivityDetailPage"
  $p = Get-Content $pagePath -Raw
  if ($p -notmatch "import\s+'package:$pkg/widgets/activity_stats_panel.dart';") {
    $p = $p -replace "(?ms)(^import\s+'.+?';)", "`$1`nimport 'package:$pkg/widgets/activity_stats_panel.dart';"
  }
  $p = $p -replace "ActivityStatsPanel\s*\(\s*activity\s*:\s*activity\s*\)", "ActivityStatsPanel(activity: widget.activity)"
  # Dé-doublonner l'import si nécessaire
  $lines = $p -split "`n"
  $seen = $false; $out = @()
  foreach ($line in $lines) {
    if ($line.TrimStart() -eq "import 'package:$pkg/widgets/activity_stats_panel.dart';") {
      if ($seen) { continue } else { $seen = $true }
    }
    $out += $line
  }
  Set-Content $pagePath ($out -join "`n")
} else {
  Write-Host "Attention: $pagePath introuvable." -ForegroundColor Yellow
}

Write-Title "flutter pub get"
try { flutter pub get | Write-Host } catch { Write-Host "Lance 'flutter pub get' manuellement si besoin." -ForegroundColor Yellow }

Write-Host "`n✅ Correction terminée. Lance 'flutter run'." -ForegroundColor Green
