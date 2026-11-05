// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newUid,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMs,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    archived,
    createdAt,
    uid,
    updatedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String name;
  final bool archived;
  final DateTime createdAt;

  /// Same id on the phone and in the cloud.
  final String uid;

  /// Epoch ms of the last change. The newer change wins when syncing.
  final int updatedAt;

  /// Changed on the phone and not yet uploaded.
  final bool dirty;
  const Project({
    required this.id,
    required this.name,
    required this.archived,
    required this.createdAt,
    required this.uid,
    required this.updatedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['uid'] = Variable<String>(uid);
    map['updated_at'] = Variable<int>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      archived: Value(archived),
      createdAt: Value(createdAt),
      uid: Value(uid),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uid: serializer.fromJson<String>(json['uid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uid': serializer.toJson<String>(uid),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Project copyWith({
    int? id,
    String? name,
    bool? archived,
    DateTime? createdAt,
    String? uid,
    int? updatedAt,
    bool? dirty,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    uid: uid ?? this.uid,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uid: data.uid.present ? data.uid.value : this.uid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('uid: $uid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, archived, createdAt, uid, updatedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.uid == this.uid &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<String> uid;
  final Value<int> updatedAt;
  final Value<bool> dirty;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<String>? uid,
    Expression<int>? updatedAt,
    Expression<bool>? dirty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (uid != null) 'uid': uid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<String>? uid,
    Value<int>? updatedAt,
    Value<bool>? dirty,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      uid: uid ?? this.uid,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('uid: $uid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Priority, int> priority =
      GeneratedColumn<int>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(Priority.green.index),
      ).withConverter<Priority>($TasksTable.$converterpriority);
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueTimeMeta = const VerificationMeta(
    'dueTime',
  );
  @override
  late final GeneratedColumn<int> dueTime = GeneratedColumn<int>(
    'due_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmMeta = const VerificationMeta('alarm');
  @override
  late final GeneratedColumn<bool> alarm = GeneratedColumn<bool>(
    'alarm',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alarm" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Recurrence, int> recurrence =
      GeneratedColumn<int>(
        'recurrence',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(Recurrence.none.index),
      ).withConverter<Recurrence>($TasksTable.$converterrecurrence);
  static const VerificationMeta _recurrenceDayMeta = const VerificationMeta(
    'recurrenceDay',
  );
  @override
  late final GeneratedColumn<int> recurrenceDay = GeneratedColumn<int>(
    'recurrence_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<Subtask>, String> subtasks =
      GeneratedColumn<String>(
        'subtasks',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<Subtask>>($TasksTable.$convertersubtasks);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newUid,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: nowMs,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    notes,
    priority,
    dueDate,
    dueTime,
    alarm,
    recurrence,
    recurrenceDay,
    done,
    doneAt,
    subtasks,
    createdAt,
    uid,
    updatedAt,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('due_time')) {
      context.handle(
        _dueTimeMeta,
        dueTime.isAcceptableOrUnknown(data['due_time']!, _dueTimeMeta),
      );
    }
    if (data.containsKey('alarm')) {
      context.handle(
        _alarmMeta,
        alarm.isAcceptableOrUnknown(data['alarm']!, _alarmMeta),
      );
    }
    if (data.containsKey('recurrence_day')) {
      context.handle(
        _recurrenceDayMeta,
        recurrenceDay.isAcceptableOrUnknown(
          data['recurrence_day']!,
          _recurrenceDayMeta,
        ),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      priority: $TasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}priority'],
        )!,
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      dueTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_time'],
      ),
      alarm: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alarm'],
      )!,
      recurrence: $TasksTable.$converterrecurrence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recurrence'],
        )!,
      ),
      recurrenceDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_day'],
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      ),
      subtasks: $TasksTable.$convertersubtasks.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}subtasks'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Priority, int, int> $converterpriority =
      const EnumIndexConverter<Priority>(Priority.values);
  static JsonTypeConverter2<Recurrence, int, int> $converterrecurrence =
      const EnumIndexConverter<Recurrence>(Recurrence.values);
  static TypeConverter<List<Subtask>, String> $convertersubtasks =
      const SubtasksConverter();
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final int? projectId;
  final String title;
  final String notes;
  final Priority priority;

  /// Local date at midnight. Null means undated.
  final DateTime? dueDate;

  /// Minutes after midnight. Null means no time.
  final int? dueTime;
  final bool alarm;
  final Recurrence recurrence;

  /// Day of month that a monthly task repeats on. Needed so that a task on
  /// the 31st goes 31 Jan -> 28 Feb -> 31 Mar instead of staying on the 28th.
  final int? recurrenceDay;
  final bool done;
  final DateTime? doneAt;

  /// Ordered steps, stored as JSON.
  final List<Subtask> subtasks;
  final DateTime createdAt;
  final String uid;
  final int updatedAt;
  final bool dirty;
  const Task({
    required this.id,
    this.projectId,
    required this.title,
    required this.notes,
    required this.priority,
    this.dueDate,
    this.dueTime,
    required this.alarm,
    required this.recurrence,
    this.recurrenceDay,
    required this.done,
    this.doneAt,
    required this.subtasks,
    required this.createdAt,
    required this.uid,
    required this.updatedAt,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority),
      );
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || dueTime != null) {
      map['due_time'] = Variable<int>(dueTime);
    }
    map['alarm'] = Variable<bool>(alarm);
    {
      map['recurrence'] = Variable<int>(
        $TasksTable.$converterrecurrence.toSql(recurrence),
      );
    }
    if (!nullToAbsent || recurrenceDay != null) {
      map['recurrence_day'] = Variable<int>(recurrenceDay);
    }
    map['done'] = Variable<bool>(done);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    {
      map['subtasks'] = Variable<String>(
        $TasksTable.$convertersubtasks.toSql(subtasks),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['uid'] = Variable<String>(uid);
    map['updated_at'] = Variable<int>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      title: Value(title),
      notes: Value(notes),
      priority: Value(priority),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      alarm: Value(alarm),
      recurrence: Value(recurrence),
      recurrenceDay: recurrenceDay == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceDay),
      done: Value(done),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      subtasks: Value(subtasks),
      createdAt: Value(createdAt),
      uid: Value(uid),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      priority: $TasksTable.$converterpriority.fromJson(
        serializer.fromJson<int>(json['priority']),
      ),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      dueTime: serializer.fromJson<int?>(json['dueTime']),
      alarm: serializer.fromJson<bool>(json['alarm']),
      recurrence: $TasksTable.$converterrecurrence.fromJson(
        serializer.fromJson<int>(json['recurrence']),
      ),
      recurrenceDay: serializer.fromJson<int?>(json['recurrenceDay']),
      done: serializer.fromJson<bool>(json['done']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
      subtasks: serializer.fromJson<List<Subtask>>(json['subtasks']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uid: serializer.fromJson<String>(json['uid']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int?>(projectId),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'priority': serializer.toJson<int>(
        $TasksTable.$converterpriority.toJson(priority),
      ),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'dueTime': serializer.toJson<int?>(dueTime),
      'alarm': serializer.toJson<bool>(alarm),
      'recurrence': serializer.toJson<int>(
        $TasksTable.$converterrecurrence.toJson(recurrence),
      ),
      'recurrenceDay': serializer.toJson<int?>(recurrenceDay),
      'done': serializer.toJson<bool>(done),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
      'subtasks': serializer.toJson<List<Subtask>>(subtasks),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uid': serializer.toJson<String>(uid),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Task copyWith({
    int? id,
    Value<int?> projectId = const Value.absent(),
    String? title,
    String? notes,
    Priority? priority,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<int?> dueTime = const Value.absent(),
    bool? alarm,
    Recurrence? recurrence,
    Value<int?> recurrenceDay = const Value.absent(),
    bool? done,
    Value<DateTime?> doneAt = const Value.absent(),
    List<Subtask>? subtasks,
    DateTime? createdAt,
    String? uid,
    int? updatedAt,
    bool? dirty,
  }) => Task(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    priority: priority ?? this.priority,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueTime: dueTime.present ? dueTime.value : this.dueTime,
    alarm: alarm ?? this.alarm,
    recurrence: recurrence ?? this.recurrence,
    recurrenceDay: recurrenceDay.present
        ? recurrenceDay.value
        : this.recurrenceDay,
    done: done ?? this.done,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    subtasks: subtasks ?? this.subtasks,
    createdAt: createdAt ?? this.createdAt,
    uid: uid ?? this.uid,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      alarm: data.alarm.present ? data.alarm.value : this.alarm,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      recurrenceDay: data.recurrenceDay.present
          ? data.recurrenceDay.value
          : this.recurrenceDay,
      done: data.done.present ? data.done.value : this.done,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      subtasks: data.subtasks.present ? data.subtasks.value : this.subtasks,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uid: data.uid.present ? data.uid.value : this.uid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('alarm: $alarm, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceDay: $recurrenceDay, ')
          ..write('done: $done, ')
          ..write('doneAt: $doneAt, ')
          ..write('subtasks: $subtasks, ')
          ..write('createdAt: $createdAt, ')
          ..write('uid: $uid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    notes,
    priority,
    dueDate,
    dueTime,
    alarm,
    recurrence,
    recurrenceDay,
    done,
    doneAt,
    subtasks,
    createdAt,
    uid,
    updatedAt,
    dirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.priority == this.priority &&
          other.dueDate == this.dueDate &&
          other.dueTime == this.dueTime &&
          other.alarm == this.alarm &&
          other.recurrence == this.recurrence &&
          other.recurrenceDay == this.recurrenceDay &&
          other.done == this.done &&
          other.doneAt == this.doneAt &&
          other.subtasks == this.subtasks &&
          other.createdAt == this.createdAt &&
          other.uid == this.uid &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<int?> projectId;
  final Value<String> title;
  final Value<String> notes;
  final Value<Priority> priority;
  final Value<DateTime?> dueDate;
  final Value<int?> dueTime;
  final Value<bool> alarm;
  final Value<Recurrence> recurrence;
  final Value<int?> recurrenceDay;
  final Value<bool> done;
  final Value<DateTime?> doneAt;
  final Value<List<Subtask>> subtasks;
  final Value<DateTime> createdAt;
  final Value<String> uid;
  final Value<int> updatedAt;
  final Value<bool> dirty;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.alarm = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceDay = const Value.absent(),
    this.done = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.subtasks = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.alarm = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceDay = const Value.absent(),
    this.done = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.subtasks = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? priority,
    Expression<DateTime>? dueDate,
    Expression<int>? dueTime,
    Expression<bool>? alarm,
    Expression<int>? recurrence,
    Expression<int>? recurrenceDay,
    Expression<bool>? done,
    Expression<DateTime>? doneAt,
    Expression<String>? subtasks,
    Expression<DateTime>? createdAt,
    Expression<String>? uid,
    Expression<int>? updatedAt,
    Expression<bool>? dirty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (dueTime != null) 'due_time': dueTime,
      if (alarm != null) 'alarm': alarm,
      if (recurrence != null) 'recurrence': recurrence,
      if (recurrenceDay != null) 'recurrence_day': recurrenceDay,
      if (done != null) 'done': done,
      if (doneAt != null) 'done_at': doneAt,
      if (subtasks != null) 'subtasks': subtasks,
      if (createdAt != null) 'created_at': createdAt,
      if (uid != null) 'uid': uid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? projectId,
    Value<String>? title,
    Value<String>? notes,
    Value<Priority>? priority,
    Value<DateTime?>? dueDate,
    Value<int?>? dueTime,
    Value<bool>? alarm,
    Value<Recurrence>? recurrence,
    Value<int?>? recurrenceDay,
    Value<bool>? done,
    Value<DateTime?>? doneAt,
    Value<List<Subtask>>? subtasks,
    Value<DateTime>? createdAt,
    Value<String>? uid,
    Value<int>? updatedAt,
    Value<bool>? dirty,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      alarm: alarm ?? this.alarm,
      recurrence: recurrence ?? this.recurrence,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay,
      done: done ?? this.done,
      doneAt: doneAt ?? this.doneAt,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      uid: uid ?? this.uid,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (dueTime.present) {
      map['due_time'] = Variable<int>(dueTime.value);
    }
    if (alarm.present) {
      map['alarm'] = Variable<bool>(alarm.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<int>(
        $TasksTable.$converterrecurrence.toSql(recurrence.value),
      );
    }
    if (recurrenceDay.present) {
      map['recurrence_day'] = Variable<int>(recurrenceDay.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (subtasks.present) {
      map['subtasks'] = Variable<String>(
        $TasksTable.$convertersubtasks.toSql(subtasks.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTime: $dueTime, ')
          ..write('alarm: $alarm, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceDay: $recurrenceDay, ')
          ..write('done: $done, ')
          ..write('doneAt: $doneAt, ')
          ..write('subtasks: $subtasks, ')
          ..write('createdAt: $createdAt, ')
          ..write('uid: $uid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPenceMeta = const VerificationMeta(
    'amountPence',
  );
  @override
  late final GeneratedColumn<int> amountPence = GeneratedColumn<int>(
    'amount_pence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Direction, int> direction =
      GeneratedColumn<int>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Direction>($LedgerEntriesTable.$converterdirection);
  @override
  late final GeneratedColumnWithTypeConverter<LedgerCategory, int> category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<LedgerCategory>($LedgerEntriesTable.$convertercategory);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    amountPence,
    direction,
    category,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount_pence')) {
      context.handle(
        _amountPenceMeta,
        amountPence.isAcceptableOrUnknown(
          data['amount_pence']!,
          _amountPenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPenceMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      amountPence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_pence'],
      )!,
      direction: $LedgerEntriesTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}direction'],
        )!,
      ),
      category: $LedgerEntriesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Direction, int, int> $converterdirection =
      const EnumIndexConverter<Direction>(Direction.values);
  static JsonTypeConverter2<LedgerCategory, int, int> $convertercategory =
      const EnumIndexConverter<LedgerCategory>(LedgerCategory.values);
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final int id;

  /// Local date at midnight.
  final DateTime date;
  final int amountPence;
  final Direction direction;
  final LedgerCategory category;
  final String note;
  const LedgerEntry({
    required this.id,
    required this.date,
    required this.amountPence,
    required this.direction,
    required this.category,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['amount_pence'] = Variable<int>(amountPence);
    {
      map['direction'] = Variable<int>(
        $LedgerEntriesTable.$converterdirection.toSql(direction),
      );
    }
    {
      map['category'] = Variable<int>(
        $LedgerEntriesTable.$convertercategory.toSql(category),
      );
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      date: Value(date),
      amountPence: Value(amountPence),
      direction: Value(direction),
      category: Value(category),
      note: Value(note),
    );
  }

  factory LedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      amountPence: serializer.fromJson<int>(json['amountPence']),
      direction: $LedgerEntriesTable.$converterdirection.fromJson(
        serializer.fromJson<int>(json['direction']),
      ),
      category: $LedgerEntriesTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'amountPence': serializer.toJson<int>(amountPence),
      'direction': serializer.toJson<int>(
        $LedgerEntriesTable.$converterdirection.toJson(direction),
      ),
      'category': serializer.toJson<int>(
        $LedgerEntriesTable.$convertercategory.toJson(category),
      ),
      'note': serializer.toJson<String>(note),
    };
  }

  LedgerEntry copyWith({
    int? id,
    DateTime? date,
    int? amountPence,
    Direction? direction,
    LedgerCategory? category,
    String? note,
  }) => LedgerEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    amountPence: amountPence ?? this.amountPence,
    direction: direction ?? this.direction,
    category: category ?? this.category,
    note: note ?? this.note,
  );
  LedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      amountPence: data.amountPence.present
          ? data.amountPence.value
          : this.amountPence,
      direction: data.direction.present ? data.direction.value : this.direction,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('amountPence: $amountPence, ')
          ..write('direction: $direction, ')
          ..write('category: $category, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, amountPence, direction, category, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.amountPence == this.amountPence &&
          other.direction == this.direction &&
          other.category == this.category &&
          other.note == this.note);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> amountPence;
  final Value<Direction> direction;
  final Value<LedgerCategory> category;
  final Value<String> note;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.amountPence = const Value.absent(),
    this.direction = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int amountPence,
    required Direction direction,
    required LedgerCategory category,
    this.note = const Value.absent(),
  }) : date = Value(date),
       amountPence = Value(amountPence),
       direction = Value(direction),
       category = Value(category);
  static Insertable<LedgerEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? amountPence,
    Expression<int>? direction,
    Expression<int>? category,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (amountPence != null) 'amount_pence': amountPence,
      if (direction != null) 'direction': direction,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? amountPence,
    Value<Direction>? direction,
    Value<LedgerCategory>? category,
    Value<String>? note,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      amountPence: amountPence ?? this.amountPence,
      direction: direction ?? this.direction,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amountPence.present) {
      map['amount_pence'] = Variable<int>(amountPence.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(
        $LedgerEntriesTable.$converterdirection.toSql(direction.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $LedgerEntriesTable.$convertercategory.toSql(category.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('amountPence: $amountPence, ')
          ..write('direction: $direction, ')
          ..write('category: $category, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $TombstonesTable extends Tombstones
    with TableInfo<$TombstonesTable, Tombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, uid, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, uid};
  @override
  Tombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tombstone(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $TombstonesTable createAlias(String alias) {
    return $TombstonesTable(attachedDatabase, alias);
  }
}

class Tombstone extends DataClass implements Insertable<Tombstone> {
  /// 'task' or 'project'.
  final String kind;
  final String uid;
  final int deletedAt;
  const Tombstone({
    required this.kind,
    required this.uid,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['uid'] = Variable<String>(uid);
    map['deleted_at'] = Variable<int>(deletedAt);
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      kind: Value(kind),
      uid: Value(uid),
      deletedAt: Value(deletedAt),
    );
  }

  factory Tombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tombstone(
      kind: serializer.fromJson<String>(json['kind']),
      uid: serializer.fromJson<String>(json['uid']),
      deletedAt: serializer.fromJson<int>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'uid': serializer.toJson<String>(uid),
      'deletedAt': serializer.toJson<int>(deletedAt),
    };
  }

  Tombstone copyWith({String? kind, String? uid, int? deletedAt}) => Tombstone(
    kind: kind ?? this.kind,
    uid: uid ?? this.uid,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  Tombstone copyWithCompanion(TombstonesCompanion data) {
    return Tombstone(
      kind: data.kind.present ? data.kind.value : this.kind,
      uid: data.uid.present ? data.uid.value : this.uid,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tombstone(')
          ..write('kind: $kind, ')
          ..write('uid: $uid, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, uid, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tombstone &&
          other.kind == this.kind &&
          other.uid == this.uid &&
          other.deletedAt == this.deletedAt);
}

class TombstonesCompanion extends UpdateCompanion<Tombstone> {
  final Value<String> kind;
  final Value<String> uid;
  final Value<int> deletedAt;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.kind = const Value.absent(),
    this.uid = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String kind,
    required String uid,
    required int deletedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       uid = Value(uid),
       deletedAt = Value(deletedAt);
  static Insertable<Tombstone> custom({
    Expression<String>? kind,
    Expression<String>? uid,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (uid != null) 'uid': uid,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? kind,
    Value<String>? uid,
    Value<int>? deletedAt,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      kind: kind ?? this.kind,
      uid: uid ?? this.uid,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('kind: $kind, ')
          ..write('uid: $uid, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    tasks,
    ledgerEntries,
    tombstones,
  ];
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  required String name,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<String> uid,
  Value<int> updatedAt,
  Value<bool> dirty,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<String> uid,
  Value<int> updatedAt,
  Value<bool> dirty,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'projects__id__tasks__project_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool tasksRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                archived: archived,
                createdAt: createdAt,
                uid: uid,
                updatedAt: updatedAt,
                dirty: dirty,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                archived: archived,
                createdAt: createdAt,
                uid: uid,
                updatedAt: updatedAt,
                dirty: dirty,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedDataByColumns<
                      Project,
                      $ProjectsTable,
                      Task,
                      $TasksTable
                    >(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._tasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProjectsTableReferences(db, table, p0).tasksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'project_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int?> projectId,
  required String title,
  Value<String> notes,
  Value<Priority> priority,
  Value<DateTime?> dueDate,
  Value<int?> dueTime,
  Value<bool> alarm,
  Value<Recurrence> recurrence,
  Value<int?> recurrenceDay,
  Value<bool> done,
  Value<DateTime?> doneAt,
  Value<List<Subtask>> subtasks,
  Value<DateTime> createdAt,
  Value<String> uid,
  Value<int> updatedAt,
  Value<bool> dirty,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int?> projectId,
  Value<String> title,
  Value<String> notes,
  Value<Priority> priority,
  Value<DateTime?> dueDate,
  Value<int?> dueTime,
  Value<bool> alarm,
  Value<Recurrence> recurrence,
  Value<int?> recurrenceDay,
  Value<bool> done,
  Value<DateTime?> doneAt,
  Value<List<Subtask>> subtasks,
  Value<DateTime> createdAt,
  Value<String> uid,
  Value<int> updatedAt,
  Value<bool> dirty,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('tasks__project_id__projects__id');

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<int>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Priority, Priority, int> get priority =>
      $composableBuilder(
        column: $table.priority,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alarm => $composableBuilder(
    column: $table.alarm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Recurrence, Recurrence, int> get recurrence =>
      $composableBuilder(
        column: $table.recurrence,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get recurrenceDay => $composableBuilder(
    column: $table.recurrenceDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<Subtask>, List<Subtask>, String>
  get subtasks => $composableBuilder(
    column: $table.subtasks,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alarm => $composableBuilder(
    column: $table.alarm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceDay => $composableBuilder(
    column: $table.recurrenceDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtasks => $composableBuilder(
    column: $table.subtasks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Priority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumn<bool> get alarm =>
      $composableBuilder(column: $table.alarm, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Recurrence, int> get recurrence =>
      $composableBuilder(
        column: $table.recurrence,
        builder: (column) => column,
      );

  GeneratedColumn<int> get recurrenceDay => $composableBuilder(
    column: $table.recurrenceDay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Subtask>, String> get subtasks =>
      $composableBuilder(column: $table.subtasks, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({bool projectId})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<Priority> priority = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> dueTime = const Value.absent(),
                Value<bool> alarm = const Value.absent(),
                Value<Recurrence> recurrence = const Value.absent(),
                Value<int?> recurrenceDay = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<List<Subtask>> subtasks = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                projectId: projectId,
                title: title,
                notes: notes,
                priority: priority,
                dueDate: dueDate,
                dueTime: dueTime,
                alarm: alarm,
                recurrence: recurrence,
                recurrenceDay: recurrenceDay,
                done: done,
                doneAt: doneAt,
                subtasks: subtasks,
                createdAt: createdAt,
                uid: uid,
                updatedAt: updatedAt,
                dirty: dirty,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                required String title,
                Value<String> notes = const Value.absent(),
                Value<Priority> priority = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> dueTime = const Value.absent(),
                Value<bool> alarm = const Value.absent(),
                Value<Recurrence> recurrence = const Value.absent(),
                Value<int?> recurrenceDay = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<List<Subtask>> subtasks = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                notes: notes,
                priority: priority,
                dueDate: dueDate,
                dueTime: dueTime,
                alarm: alarm,
                recurrence: recurrence,
                recurrenceDay: recurrenceDay,
                done: done,
                doneAt: doneAt,
                subtasks: subtasks,
                createdAt: createdAt,
                uid: uid,
                updatedAt: updatedAt,
                dirty: dirty,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$TasksTableReferences._projectIdTable(
                          db,
                        ),
                        referencedColumn: $$TasksTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required int amountPence,
      required Direction direction,
      required LedgerCategory category,
      Value<String> note,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> amountPence,
      Value<Direction> direction,
      Value<LedgerCategory> category,
      Value<String> note,
    });

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPence => $composableBuilder(
    column: $table.amountPence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Direction, Direction, int> get direction =>
      $composableBuilder(
        column: $table.direction,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LedgerCategory, LedgerCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPence => $composableBuilder(
    column: $table.amountPence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amountPence => $composableBuilder(
    column: $table.amountPence,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Direction, int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LedgerCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntry,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (
            LedgerEntry,
            BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>,
          ),
          LedgerEntry,
          PrefetchHooks Function()
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> amountPence = const Value.absent(),
                Value<Direction> direction = const Value.absent(),
                Value<LedgerCategory> category = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                date: date,
                amountPence: amountPence,
                direction: direction,
                category: category,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int amountPence,
                required Direction direction,
                required LedgerCategory category,
                Value<String> note = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                date: date,
                amountPence: amountPence,
                direction: direction,
                category: category,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LedgerEntriesTable,
                    LedgerEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntry,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (
        LedgerEntry,
        BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntry>,
      ),
      LedgerEntry,
      PrefetchHooks Function()
    >;
typedef $$TombstonesTableCreateCompanionBuilder = TombstonesCompanion Function({
  required String kind,
  required String uid,
  required int deletedAt,
  Value<int> rowid,
});
typedef $$TombstonesTableUpdateCompanionBuilder = TombstonesCompanion Function({
  Value<String> kind,
  Value<String> uid,
  Value<int> deletedAt,
  Value<int> rowid,
});

class $$TombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TombstonesTable,
          Tombstone,
          $$TombstonesTableFilterComposer,
          $$TombstonesTableOrderingComposer,
          $$TombstonesTableAnnotationComposer,
          $$TombstonesTableCreateCompanionBuilder,
          $$TombstonesTableUpdateCompanionBuilder,
          (
            Tombstone,
            BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>,
          ),
          Tombstone,
          PrefetchHooks Function()
        > {
  $$TombstonesTableTableManager(_$AppDatabase db, $TombstonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<int> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion(
                kind: kind,
                uid: uid,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String uid,
                required int deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion.insert(
                kind: kind,
                uid: uid,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TombstonesTable, Tombstone>(table),
                  BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TombstonesTable,
      Tombstone,
      $$TombstonesTableFilterComposer,
      $$TombstonesTableOrderingComposer,
      $$TombstonesTableAnnotationComposer,
      $$TombstonesTableCreateCompanionBuilder,
      $$TombstonesTableUpdateCompanionBuilder,
      (Tombstone, BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>),
      Tombstone,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$TombstonesTableTableManager get tombstones =>
      $$TombstonesTableTableManager(_db, _db.tombstones);
}
