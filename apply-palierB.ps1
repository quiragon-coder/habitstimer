# EXÉCUTION :
#   1) Ouvrir PowerShell dans le dossier du repo (là où il y a pubspec.yaml)
#   2) .\apply-palierB.ps1
#   3) Lancer ensuite: flutter pub get && flutter run

# ==========================
# apply-palierB.ps1
# ==========================
$ErrorActionPreference = "Stop"

function Write-Title($t) { Write-Host "==> $t" -ForegroundColor Cyan }

# 0) Vérifs de base
if (-not (Test-Path "pubspec.yaml")) {
  Write-Error "pubspec.yaml introuvable. Lance le script depuis la racine du projet Flutter."
}

# 1) Dépendances (fl_chart, intl)
Write-Title "Mise à jour de pubspec.yaml (fl_chart, intl)"
$pubspec = Get-Content "pubspec.yaml" -Raw

# Sauvegarde
Copy-Item "pubspec.yaml" "pubspec.yaml.bak" -Force

# Ajoute les deps si manquantes
if ($pubspec -notmatch "(?ms)dependencies:\s*[\s\S]*fl_chart:") {
  $pubspec = $pubspec -replace "(?ms)(^dependencies:\s*\n)", "`$1  fl_chart: ^0.69.0`n"
}
if ($pubspec -notmatch "(?ms)dependencies:\s*[\s\S]*intl:") {
  $pubspec = $pubspec -replace "(?ms)(^dependencies:\s*\n)", "`$1  intl: ^0.19.0`n"
}
Set-Content "pubspec.yaml" $pubspec -NoNewline
Write-Host "pubspec.yaml mis à jour."

# 2) Arborescences
Write-Title "Création des dossiers nécessaires"
New-Item -ItemType Directory -Force -Path "lib\models" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\widgets" | Out-Null

# 3) Modèles stats
Write-Title "Création lib/models/stats.dart"
@'
import 'package:flutter/foundation.dart';

@immutable
class DailyStat {
  final DateTime day; // tronqué à minuit local
  final int minutes;  // minutes totales sur ce jour
  const DailyStat({required this.day, required this.minutes});
}

@immutable
class HourlyBucket {
  final int hour;     // 0..23
  final int minutes;  // minutes effectuées dans cette heure
  const HourlyBucket({required this.hour, required this.minutes});
}
'@ | Set-Content "lib/models/stats.dart"

# 4) Providers pour stats (Riverpod)
Write-Title "Création lib/providers_stats.dart"
@'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitstimer/models/stats.dart';
import 'package:habitstimer/services/database_service.dart';
import 'providers.dart';

final statsTodayProvider = FutureProvider.family<int, String>((ref, activityId) async {
  final db = ref.read(dbProvider);
  return db.minutesForActivityOnDay(activityId, DateTime.now());
});

final statsLast7DaysProvider = FutureProvider.family<List<DailyStat>, String>((ref, activityId) async {
  final db = ref.read(dbProvider);
  return db.last7DaysStats(activityId);
});

final hourlyTodayProvider = FutureProvider.family<List<HourlyBucket>, String>((ref, activityId) async {
  final db = ref.read(dbProvider);
  return db.hourlyDistribution(activityId, DateTime.now());
});
'@ | Set-Content "lib/providers_stats.dart"

# 5) Widgets de graphes
Write-Title "Création lib/widgets/hourly_bars_chart.dart"
@'
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitstimer/models/stats.dart';

class HourlyBarsChart extends StatelessWidget {
  final List<HourlyBucket> data;
  const HourlyBarsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final groups = data.map((b) => BarChartGroupData(
      x: b.hour,
      barRods: [BarChartRodData(toY: b.minutes.toDouble(), width: 8)],
    )).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final h = value.toInt();
                return Text(h % 6 == 0 ? '$h' : '', style: const TextStyle(fontSize: 10));
              },
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}
'@ | Set-Content "lib/widgets/hourly_bars_chart.dart"

Write-Title "Création lib/widgets/weekly_bars_chart.dart"
@'
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitstimer/models/stats.dart';
import 'package:intl/intl.dart';

class WeeklyBarsChart extends StatelessWidget {
  final List<DailyStat> data;
  const WeeklyBarsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.E();
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      groups.add(BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: d.minutes.toDouble(), width: 14, borderRadius: BorderRadius.circular(4))],
        showingTooltipIndicators: const [0],
      ));
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(df.format(data[i].day), style: const TextStyle(fontSize: 10)),
                );
              },
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(enabled: true),
        ),
      ),
    );
  }
}
'@ | Set-Content "lib/widgets/weekly_bars_chart.dart"

# 6) Panneau de stats (widget autonome)
Write-Title "Création lib/widgets/activity_stats_panel.dart"
@'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitstimer/models/activity.dart';
import 'package:habitstimer/widgets/hourly_bars_chart.dart';
import 'package:habitstimer/widgets/weekly_bars_chart.dart';
import 'package:habitstimer/providers_stats.dart';

class ActivityStatsPanel extends ConsumerWidget {
  final Activity activity;
  const ActivityStatsPanel({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMinutes = ref.watch(statsTodayProvider(activity.id));
    final weekly = ref.watch(statsLast7DaysProvider(activity.id));
    final hourly = ref.watch(hourlyTodayProvider(activity.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Statistiques', style: Theme.of(context).textTheme.titleLarge),

        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: todayMinutes.when(
                    data: (m) => Text('Aujourd’hui: ${m} min', style: Theme.of(context).textTheme.titleMedium),
                    loading: () => const Text('Chargement…'),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Répartition horaire (aujourd’hui)', style: Theme.of(context).textTheme.titleMedium),
                hourly.when(
                  data: (data) => HourlyBarsChart(data: data),
                  loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Erreur: $e'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Derniers 7 jours', style: Theme.of(context).textTheme.titleMedium),
                weekly.when(
                  data: (data) => WeeklyBarsChart(data: data),
                  loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Erreur: $e'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
'@ | Set-Content "lib/widgets/activity_stats_panel.dart"

# 7) Extensions du DatabaseService : méthodes de stats
#    - On ajoute 3 méthodes: minutesForActivityOnDay, last7DaysStats, hourlyDistribution
#    - On suppose que getSessionsByActivity(String) et getPausesBySession(String) existent.
#    - Le script injecte proprement avant la dernière '}' de la classe DatabaseService.

$svcPath = "lib/services/database_service.dart"
if (-not (Test-Path $svcPath)) {
  Write-Host "ATTENTION: $svcPath introuvable. Je saute l'injection du service. (Tu pourras déplacer les méthodes dans ton service manuellement.)" -ForegroundColor Yellow
} else {
  Write-Title "Injection des méthodes de stats dans $svcPath"
  $svc = Get-Content $svcPath -Raw
  Copy-Item $svcPath "$svcPath.bak" -Force

  $methods = @'
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
'@

  # On tente d'insérer avant la dernière '}' de la classe DatabaseService
  if ($svc -match "class\s+DatabaseService[^{]*\{") {
    # Cherche la position de la DERNIÈRE accolade qui ferme la classe
    $lastBraceIndex = ($svc.LastIndexOf("}"))
    if ($lastBraceIndex -gt 0) {
      $svcNew = $svc.Insert($lastBraceIndex, $methods)
      Set-Content $svcPath $svcNew
      Write-Host "Méthodes injectées dans DatabaseService."
    } else {
      Write-Host "Impossible de localiser la fin de la classe DatabaseService. Fichier laissé intact." -ForegroundColor Yellow
    }
  } else {
    Write-Host "Classe DatabaseService introuvable. Fichier laissé intact." -ForegroundColor Yellow
  }
}

# 8) Injection dans ActivityDetailPage : import + ajout du panneau
$pagePath = "lib/pages/activity_detail_page.dart"
if (-not (Test-Path $pagePath)) {
  Write-Host "ATTENTION: $pagePath introuvable. Je ne peux pas insérer visuellement le panneau." -ForegroundColor Yellow
} else {
  Write-Title "Mise à jour de $pagePath (import + panneau de stats)"

  Copy-Item $pagePath "$pagePath.bak" -Force
  $page = Get-Content $pagePath -Raw

  # Ajoute imports si absents
  if ($page -notmatch "widgets/activity_stats_panel.dart") {
    $page = $page -replace "(?ms)^import\s+'package:[^;]+;\s*", "`$0import 'package:habitstimer/widgets/activity_stats_panel.dart';`n"
  }

  # Essaye d'insérer ActivityStatsPanel dans le premier children: [...]
  $inserted = $false
  $pattern = "children\s*:\s*\["
  $m = [regex]::Match($page, $pattern)
  if ($m.Success) {
    $idx = $m.Index + $m.Length
    $insertion = "`n          const SizedBox(height: 8),`n          ActivityStatsPanel(activity: activity),`n"
    $page = $page.Insert($idx, $insertion)
    $inserted = $true
  }

  Set-Content $pagePath $page
  if ($inserted) {
    Write-Host "Panneau inséré dans la première liste de widgets (children: [...])."
  } else {
    Write-Host "Impossible de localiser une liste children: [...]. Le widget a été simplement importé; ajoute ActivityStatsPanel(activity: activity) manuellement dans l'UI." -ForegroundColor Yellow
  }
}

# 9) flutter pub get
Write-Title "Installation des dépendances (flutter pub get)"
try {
  flutter pub get | Write-Host
} catch {
  Write-Host "Note: 'flutter pub get' a échoué dans le script. Tu peux l'exécuter manuellement." -ForegroundColor Yellow
}

Write-Host "`n✅ Palier B: fichiers créés, dépendances ajoutées, panneau de stats prêt. Lance 'flutter run' pour tester." -ForegroundColor Green
