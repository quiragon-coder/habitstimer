param(
  [string]$ProjectPath = "C:\Users\Quiragon\Desktop\Habit timer"
)

$ErrorActionPreference = "Stop"

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[ERR]  $m" -ForegroundColor Red }

if (-not (Test-Path $ProjectPath)) { Err "Dossier introuvable: $ProjectPath"; exit 1 }
Set-Location $ProjectPath
if (-not (Test-Path ".\pubspec.yaml")) { Err "pubspec.yaml introuvable. Place-toi à la racine du projet."; exit 1 }

# Backup
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bak = Join-Path $ProjectPath ("tools\backup-" + $stamp)
New-Item -ItemType Directory -Force -Path $bak | Out-Null

function BackupFile($rel){
  $src = Join-Path $ProjectPath $rel
  if (Test-Path $src){
    $dstDir = Split-Path (Join-Path $bak $rel) -Parent
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Copy-Item $src (Join-Path $bak $rel)
  }
}

$target = "lib\pages\activities_list_page.dart"
BackupFile $target

# Write corrected file content
$code = @"
REPLACE_ACTIVITIES
"@

$code = $code -replace "REPLACE_ACTIVITIES", @'
import ''package:flutter/material.dart'';
import ''package:flutter_riverpod/flutter_riverpod.dart'';
import ''../providers.dart'';
import ''../models/activity.dart'';
import ''../services/database_service.dart'';
import ''../widgets/activity_controls.dart'';
import ''activity_detail_page.dart'';

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
        title: const Text(''Habits Timer''),
        actions: [
          IconButton(onPressed: ()=> Navigator.pushNamed(context, ''/heatmap''), icon: const Icon(Icons.grid_on)),
          IconButton(onPressed: ()=> Navigator.pushNamed(context, ''/settings''), icon: const Icon(Icons.settings)),
        ],
      ),
      body: activitiesAsync.when(
        data: (items){
          if (items.isEmpty) {
            return const Center(child: Text(''Ajoute une activité avec le +''));
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
                    future: db.minutesForWeek(DateTime.now(), a.id!),
                    builder: (c, s) => Text(''Semaine: ${s.data ?? 0} min'' + (a.goalMinutesPerWeek!=null ? '' / ${a.goalMinutesPerWeek} min'' : '''')),
                  ),
                  onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> ActivityDetailPage(activity: a))),
                  trailing: ActivityControls(activity: a),
                ),
              );
            },
          );
        },
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e, st)=> Center(child: Text(''Erreur: $e''))
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final a = await _askNewActivity(context);
          if (a == null) return;
          final id = await db.insertActivity(a);
          // Si vous avez copyWith, vous pouvez faire: final created = a.copyWith(id: id);
          // Puis éventuellement naviguer vers la page détail.
          // Ici on se contente de rafraîchir la liste :
          ref.invalidate(activitiesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Activity?> _askNewActivity(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (c){
        final ctrl = TextEditingController();
        double weekMin = 300; // 5h
        double dayMin = 60;
        double daysPerWeek = 3;
        return StatefulBuilder(
          builder: (c, setState) => AlertDialog(
            title: const Text(''Nouvelle activité''),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: ctrl, decoration: const InputDecoration(labelText: ''Nom'')),
                  const SizedBox(height: 12),
                  Row(children: [const Text(''Objectif h/sem''), Expanded(child: Slider(min:0, max:1200, divisions:120, value: weekMin, label: ''${(weekMin/60).toStringAsFixed(1)}h'', onChanged: (v)=> setState(()=> weekMin=v)))]),
                  Row(children: [const Text(''Jours/sem''), Expanded(child: Slider(min:0, max:7, divisions:7, value: daysPerWeek, label: daysPerWeek.toStringAsFixed(0), onChanged: (v)=> setState(()=> daysPerWeek=v)))]),
                  Row(children: [const Text(''Objectif h/jour''), Expanded(child: Slider(min:0, max:600, divisions:120, value: dayMin, label: ''${(dayMin/60).toStringAsFixed(1)}h'', onChanged: (v)=> setState(()=> dayMin=v)))]),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: ()=> Navigator.pop(c), child: const Text(''Annuler'')),
              FilledButton(onPressed: ()=> Navigator.pop(c, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()), child: const Text(''Créer'')),
            ],
          ),
        );
      }
    );
    if (name==null) return null;
    return Activity(
      name: name,
      goalMinutesPerWeek: weekMin.round(),
      goalDaysPerWeek: daysPerWeek.round(),
      goalMinutesPerDay: dayMin.round(),
    );
  }
}

'@

New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
Set-Content -Path $target -Value $code -Encoding UTF8
Ok "activities_list_page.dart réécrit"

# Ensure import path for ActivityControls exists
$widgetPath = "lib\widgets\activity_controls.dart"
if (-not (Test-Path $widgetPath)) {
  Warn "Le widget ActivityControls semble manquant. Assure-toi d'avoir lib/widgets/activity_controls.dart"
}

Ok "Terminé. Sauvegarde dans $bak"
