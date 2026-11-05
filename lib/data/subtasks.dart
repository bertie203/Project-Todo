import 'dart:convert';

import 'package:drift/drift.dart';

/// One step of a task. Steps are kept in order inside their task.
class Subtask {
  const Subtask(this.title, {this.done = false});
  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  static Subtask fromJson(Object? j) {
    if (j is String) return Subtask(j);
    final m = j as Map<String, dynamic>;
    return Subtask(m['title'] as String? ?? '', done: m['done'] == true);
  }

  @override
  bool operator ==(Object other) =>
      other is Subtask && other.title == title && other.done == done;

  @override
  int get hashCode => Object.hash(title, done);
}

/// Stores the steps as a JSON array in one text column, so they sync with
/// their task.
class SubtasksConverter extends TypeConverter<List<Subtask>, String> {
  const SubtasksConverter();

  @override
  List<Subtask> fromSql(String fromDb) => decodeSubtasks(fromDb);

  @override
  String toSql(List<Subtask> value) => encodeSubtasks(value);
}

List<Subtask> decodeSubtasks(String? s) {
  if (s == null || s.isEmpty) return const [];
  try {
    return (jsonDecode(s) as List).map(Subtask.fromJson).toList();
  } catch (_) {
    return const [];
  }
}

String encodeSubtasks(List<Subtask> list) =>
    jsonEncode(list.map((s) => s.toJson()).toList());
