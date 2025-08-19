# Apply Habits Timer Patch Script
param()

$ErrorActionPreference = "Stop"

# Backup folder
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "tools/backup-$timestamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Write-Host "== Backing up files to $backupDir =="

$filesToPatch = @(
    "lib/providers.dart",
    "lib/services/database_service.dart",
    "lib/pages/activities_list_page.dart"
)

foreach ($f in $filesToPatch) {
    if (Test-Path $f) {
        $dest = Join-Path $backupDir ($f -replace '[\\/]', '_')
        Copy-Item $f $dest -Force
        Write-Host "Backed up $f"
    }
}

# Patch providers.dart
$providersFile = "lib/providers.dart"
if (Test-Path $providersFile) {
    $content = Get-Content $providersFile -Raw
    if ($content -notmatch "tickerProvider") {
        Add-Content $providersFile "`n// Provides a ticker that updates every second`nfinal tickerProvider = StreamProvider<int>((ref) {`n  return Stream.periodic(Duration(seconds: 1), (count) => count);`n});`n"
        Write-Host "Patched tickerProvider into providers.dart"
    }
}

# Patch database_service.dart
$dbFile = "lib/services/database_service.dart"
if (Test-Path $dbFile) {
    $content = Get-Content $dbFile -Raw
    if ($content -notmatch "activeDuration") {
        Add-Content $dbFile "`n  // Calculate active duration for a session`n  Future<Duration> activeDuration(int sessionId) async {`n    final db = await database;`n    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId]);`n    if (rows.isEmpty) return Duration.zero;`n    final row = rows.first;`n    final start = DateTime.parse(row['startTime'] as String);`n    final endStr = row['endTime'] as String?;`n    final end = endStr != null ? DateTime.parse(endStr) : DateTime.now();`n    return end.difference(start);`n  }`n" 
        Add-Content $dbFile "`n  Future<int> startSession(int activityId) async {`n    final db = await database;`n    return db.insert('sessions', {`n      'activityId': activityId,`n      'startTime': DateTime.now().toIso8601String(),`n    });`n  }`n"
        Add-Content $dbFile "`n  Future<void> stopSession(int sessionId) async {`n    final db = await database;`n    await db.update('sessions', {`n      'endTime': DateTime.now().toIso8601String(),`n    }, where: 'id = ?', whereArgs: [sessionId]);`n  }`n"
        Add-Content $dbFile "`n  Future<void> togglePause(int sessionId) async {`n    // Example toggle logic: here just closes session`n    await stopSession(sessionId);`n  }`n"
        Write-Host "Patched database_service.dart with activeDuration, start/stop/togglePause"
    }
}

# Patch activities_list_page.dart
$pageFile = "lib/pages/activities_list_page.dart"
if (Test-Path $pageFile) {
    if ((Get-Content $pageFile -Raw) -notmatch "ActivityControls") {
        Add-Content $pageFile "`n// TODO: Place ActivityControls(activity: a) where you render buttons for each activity card.`nimport '../widgets/activity_controls.dart';`n"
        Write-Host "Patched activities_list_page.dart with TODO and import for ActivityControls"
    }
}

# Create widgets/activity_controls.dart
$widgetDir = "lib/widgets"
if (!(Test-Path $widgetDir)) {
    New-Item -ItemType Directory -Force -Path $widgetDir | Out-Null
}
$widgetFile = Join-Path $widgetDir "activity_controls.dart"
if (!(Test-Path $widgetFile)) {
@"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import '../providers.dart';

class ActivityControls extends ConsumerWidget {
  final Activity activity;
  const ActivityControls({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tickerProvider); // rebuild every second

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            DatabaseService().startSession(activity.id!);
          },
        ),
        IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () {
            // TODO: manage current session id properly
          },
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          onPressed: () {
            // TODO: manage current session id properly
          },
        ),
      ],
    );
  }
}
"@ | Set-Content $widgetFile -Force
    Write-Host "Created widgets/activity_controls.dart"
}

Write-Host "== Patch applied. Check TODOs for manual integration =="
