# apply-ui-fixes.ps1
$ErrorActionPreference = "Stop"

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[ERR]  $m" -ForegroundColor Red }

# 0) Sanity check
if (-not (Test-Path ".\pubspec.yaml")) {
  Write-Err "pubspec.yaml introuvable. Lance ce script à la racine du projet."
  exit 1
}

# 1) Sauvegardes
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "tools\backup-$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
if (Test-Path "lib\pages\activities_list_page.dart") { Copy-Item "lib\pages\activities_list_page.dart" "$backupDir\activities_list_page.dart" }
if (Test-Path "lib\widgets\activity_controls.dart") { Copy-Item "lib\widgets\activity_controls.dart" "$backupDir\activity_controls.dart" }

# 2) Crée/écrase activity_controls.dart
New-Item -ItemType Directory -Force -Path "lib\widgets" | Out-Null
@'
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/database_service.dart';

class ActivityControls extends StatefulWidget {
  final Activity activity;
  const ActivityControls({super.key, required this.activity});

  @override
  State<ActivityControls> createState() => _ActivityControlsState();
}

class _ActivityControlsState extends State<ActivityControls> {
  final db = DatabaseService();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  Future<void> _refreshElapsed() async {
    try {
      final sec = await db.activeDuration(activityId: widget.activity.id!);
      setState(() {
        _elapsed = Duration(seconds: sec);
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // Tick chaque seconde pour rafraîchir l’affichage
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refreshElapsed());
    _refreshElapsed();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    }
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fmt(_elapsed), style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Démarrer',
          icon: const Icon(Icons.play_arrow),
          onPressed: () async {
            if (widget.activity.id == null) return;
            await db.startSession(widget.activity.id!);
            await _refreshElapsed();
          },
        ),
        IconButton(
          tooltip: 'Pause/Reprendre',
          icon: const Icon(Icons.pause),
          onPressed: () async {
            if (widget.activity.id == null) return;
            await db.togglePause(activityId: widget.activity.id!);
            await _refreshElapsed();
          },
        ),
        IconButton(
          tooltip: 'Arrêter',
          icon: const Icon(Icons.stop),
          onPressed: () async {
            if (widget.activity.id == null) return;
            await db.stopSession(activityId: widget.activity.id!);
            await _refreshElapsed();
          },
        ),
      ],
    );
  }
}
'@ | Set-Content -Encoding UTF8 -LiteralPath "lib\widgets\activity_controls.dart"

# 3) Remplace activities_list_page.dart complet par une version propre
@'
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../providers.dart";
import "../models/activity.dart";
import "../services/database_service.dart";
import "../widgets/activity_controls.dart";
import "activity_detail_page.dart";

class ActivitiesListPage extends ConsumerStatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  ConsumerState<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends ConsumerState<ActivitiesListPage> {
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Habits Timer"),
        actions: [
          IconButton(onPressed: ()=> Navigator.pushNamed(context, "/heatmap"), icon: const Icon(Icons.grid_on)),
          IconButton(onPressed: ()=> Navigator.pushNamed(context, "/settings"), icon: const Icon(Icons.settings)),
        ],
      ),
      body: activitiesAsync.when(
        data: (items){
          if (items.isEmpty) {
            return const Center(child: Text("Ajoute une activité avec le +"));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i){
              final a = items[i];
              return Card(
                child: ListTile(
                  title: Text(a.name),
                  subtitle: FutureBuilder<int>(
                    future: db.minutesForWeek(DateTime.now(), a.id),
                    builder: (c, s) {
                      final txt = (s.data ?? 0).toString();
                      final goal = a.goalMinutesPerWeek!=null ? " / ${a.goalMinutesPerWeek} min" : "";
                      return Text("Semaine: $txt min$goal");
                    },
                  ),
                  onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> ActivityDetailPage(activity: a))),
                  trailing: ActivityControls(activity: a),
                ),
              );
            },
          );
        },
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e, st)=> Center(child: Text("Erreur: $e")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final a = await _askNewActivity(context);
          if (a == null) return;
          await db.insertActivity(a);
          ref.refresh(activitiesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Activity?> _askNewActivity(BuildContext context) async {
    return showDialog<Activity>(
      context: context,
      builder: (c){
        final ctrl = TextEditingController();
        double weekMin = 300; // 5h
        double dayMin = 60;   // 1h
        double daysPerWeek = 3;
        return StatefulBuilder(
          builder: (c, setState) => AlertDialog(
            title: const Text("Nouvelle activité"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Nom")),
                  const SizedBox(height: 12),
                  Row(children: [const Text("Objectif h/sem"), Expanded(child: Slider(min:0, max:1200, divisions:120, value: weekMin, label: "${(weekMin/60).toStringAsFixed(1)}h", onChanged: (v)=> setState(()=> weekMin=v)))]),
                  Row(children: [const Text("Jours/sem"), Expanded(child: Slider(min:0, max:7, divisions:7, value: daysPerWeek, label: daysPerWeek.toStringAsFixed(0), onChanged: (v)=> setState(()=> daysPerWeek=v)))]),
                  Row(children: [const Text("Objectif h/jour"), Expanded(child: Slider(min:0, max:600, divisions:120, value: dayMin, label: "${(dayMin/60).toStringAsFixed(1)}h", onChanged: (v)=> setState(()=> dayMin=v)))]),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: ()=> Navigator.pop(c), child: const Text("Annuler")),
              FilledButton(
                onPressed: (){
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(c, Activity(
                    name: name,
                    goalMinutesPerWeek: weekMin.round(),
                    goalDaysPerWeek: daysPerWeek.round(),
                    goalMinutesPerDay: dayMin.round(),
                  ));
                },
                child: const Text("Créer"),
              ),
            ],
          ),
        );
      }
    );
  }
}
'@ | Set-Content -Encoding UTF8 -LiteralPath "lib\pages\activities_list_page.dart"

Write-Info "Formatage Dart"
dart format --fix lib\pages\activities_list_page.dart lib\widgets\activity_controls.dart | Out-Null

# 4) Vérif rapide côté Flutter (facultatif, ne stoppe pas le script si Flutter n’est pas dans le PATH)
try {
  flutter analyze
} catch {
  Write-Warn "flutter analyze a renvoyé une erreur, continue..."
}

# 5) Commit + push
git add lib\pages\activities_list_page.dart lib\widgets\activity_controls.dart
git commit -m "feat: ActivityControls widget + fix new-activity dialog to use sliders"
git pull --rebase origin main
git push -u origin main

Write-Ok "Terminé."
