import 'dart:convert';

import '../data/database.dart';
import '../logic/uid.dart';

const backupFormatVersion = 2;

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

Future<String> exportJson(AppDatabase db) async {
  final projects = await db.select(db.projects).get();
  final tasks = await db.select(db.tasks).get();
  final ledger = await db.select(db.ledgerEntries).get();
  final data = {
    'format': 'project-todo',
    'version': backupFormatVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'projects': [
      for (final p in projects)
        {
          'id': p.id,
          'uid': p.uid,
          'name': p.name,
          'archived': p.archived,
          'createdAt': p.createdAt.toIso8601String(),
        },
    ],
    'tasks': [
      for (final t in tasks)
        {
          'id': t.id,
          'uid': t.uid,
          'projectId': t.projectId,
          'title': t.title,
          'notes': t.notes,
          'priority': t.priority.name,
          'dueDate': t.dueDate == null ? null : _date(t.dueDate!),
          'dueTime': t.dueTime,
          'alarm': t.alarm,
          'recurrence': t.recurrence.name,
          'recurrenceDay': t.recurrenceDay,
          'done': t.done,
          'doneAt': t.doneAt?.toIso8601String(),
          'createdAt': t.createdAt.toIso8601String(),
        },
    ],
    'ledger': [
      for (final e in ledger)
        {
          'id': e.id,
          'date': _date(e.date),
          'amountPence': e.amountPence,
          'direction': e.direction == Direction.moneyIn ? 'in' : 'out',
          'category': e.category.name,
          'note': e.note,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

class BackupData {
  BackupData(this.projects, this.tasks, this.ledger);
  final List<Project> projects;
  final List<Task> tasks;
  final List<LedgerEntry> ledger;
}

/// Parses a backup file. Throws [FormatException] if it is not valid.
BackupData parseBackup(String json) {
  final Object? raw;
  try {
    raw = jsonDecode(json);
  } catch (_) {
    throw const FormatException('Not a JSON file');
  }
  if (raw is! Map || raw['format'] != 'project-todo') {
    throw const FormatException('Not a Project-Todo backup');
  }
  if ((raw['version'] as int? ?? 0) > backupFormatVersion) {
    throw const FormatException('Backup is from a newer version of the app');
  }
  try {
    final projects = [
      for (final p in raw['projects'] as List)
        Project(
          id: p['id'] as int,
          name: p['name'] as String,
          archived: p['archived'] as bool,
          createdAt: DateTime.parse(p['createdAt'] as String),
          uid: p['uid'] as String? ?? newUid(),
          updatedAt: nowMs(),
          dirty: true,
        ),
    ];
    final tasks = [
      for (final t in raw['tasks'] as List)
        Task(
          id: t['id'] as int,
          projectId: t['projectId'] as int?,
          title: t['title'] as String,
          notes: t['notes'] as String? ?? '',
          priority: Priority.values.byName(t['priority'] as String),
          dueDate: t['dueDate'] == null
              ? null
              : _parseDate(t['dueDate'] as String),
          dueTime: t['dueTime'] as int?,
          alarm: t['alarm'] as bool,
          recurrence: Recurrence.values.byName(t['recurrence'] as String),
          recurrenceDay: t['recurrenceDay'] as int?,
          done: t['done'] as bool,
          doneAt: t['doneAt'] == null
              ? null
              : DateTime.parse(t['doneAt'] as String),
          createdAt: DateTime.parse(t['createdAt'] as String),
          uid: t['uid'] as String? ?? newUid(),
          updatedAt: nowMs(),
          dirty: true,
        ),
    ];
    final ledger = [
      for (final e in raw['ledger'] as List)
        LedgerEntry(
          id: e['id'] as int,
          date: _parseDate(e['date'] as String),
          amountPence: e['amountPence'] as int,
          direction: switch (e['direction']) {
            'in' => Direction.moneyIn,
            'out' => Direction.moneyOut,
            _ => throw const FormatException('Bad direction'),
          },
          category: LedgerCategory.values.byName(e['category'] as String),
          note: e['note'] as String? ?? '',
        ),
    ];
    return BackupData(projects, tasks, ledger);
  } on FormatException {
    rethrow;
  } catch (e) {
    throw FormatException('Backup file is damaged: $e');
  }
}

Future<void> importBackup(AppDatabase db, BackupData data) => db.replaceAll(
  projectRows: data.projects,
  taskRows: data.tasks,
  ledgerRows: data.ledger,
);
