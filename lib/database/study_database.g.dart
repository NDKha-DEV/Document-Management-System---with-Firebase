// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectPkMeta =
      const VerificationMeta('subjectPk');
  @override
  late final GeneratedColumn<String> subjectPk = GeneratedColumn<String>(
      'subject_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 250),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _teacherMeta =
      const VerificationMeta('teacher');
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
      'teacher', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#3b82f6'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('book'));
  static const VerificationMeta _creditsMeta =
      const VerificationMeta('credits');
  @override
  late final GeneratedColumn<int> credits = GeneratedColumn<int>(
      'credits', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        subjectPk,
        name,
        code,
        teacher,
        colorHex,
        icon,
        credits,
        order,
        dateTimeModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<Subject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_pk')) {
      context.handle(_subjectPkMeta,
          subjectPk.isAcceptableOrUnknown(data['subject_pk']!, _subjectPkMeta));
    } else if (isInserting) {
      context.missing(_subjectPkMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(_teacherMeta,
          teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('credits')) {
      context.handle(_creditsMeta,
          credits.isAcceptableOrUnknown(data['credits']!, _creditsMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectPk};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      subjectPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_pk'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      teacher: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}teacher']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      credits: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}credits'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final String subjectPk;
  final String name;
  final String code;
  final String? teacher;
  final String colorHex;
  final String icon;
  final int credits;
  final int order;
  final DateTime dateTimeModified;
  const Subject(
      {required this.subjectPk,
      required this.name,
      required this.code,
      this.teacher,
      required this.colorHex,
      required this.icon,
      required this.credits,
      required this.order,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_pk'] = Variable<String>(subjectPk);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || teacher != null) {
      map['teacher'] = Variable<String>(teacher);
    }
    map['color_hex'] = Variable<String>(colorHex);
    map['icon'] = Variable<String>(icon);
    map['credits'] = Variable<int>(credits);
    map['order'] = Variable<int>(order);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      subjectPk: Value(subjectPk),
      name: Value(name),
      code: Value(code),
      teacher: teacher == null && nullToAbsent
          ? const Value.absent()
          : Value(teacher),
      colorHex: Value(colorHex),
      icon: Value(icon),
      credits: Value(credits),
      order: Value(order),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      subjectPk: serializer.fromJson<String>(json['subjectPk']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      teacher: serializer.fromJson<String?>(json['teacher']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      icon: serializer.fromJson<String>(json['icon']),
      credits: serializer.fromJson<int>(json['credits']),
      order: serializer.fromJson<int>(json['order']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectPk': serializer.toJson<String>(subjectPk),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'teacher': serializer.toJson<String?>(teacher),
      'colorHex': serializer.toJson<String>(colorHex),
      'icon': serializer.toJson<String>(icon),
      'credits': serializer.toJson<int>(credits),
      'order': serializer.toJson<int>(order),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  Subject copyWith(
          {String? subjectPk,
          String? name,
          String? code,
          Value<String?> teacher = const Value.absent(),
          String? colorHex,
          String? icon,
          int? credits,
          int? order,
          DateTime? dateTimeModified}) =>
      Subject(
        subjectPk: subjectPk ?? this.subjectPk,
        name: name ?? this.name,
        code: code ?? this.code,
        teacher: teacher.present ? teacher.value : this.teacher,
        colorHex: colorHex ?? this.colorHex,
        icon: icon ?? this.icon,
        credits: credits ?? this.credits,
        order: order ?? this.order,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('subjectPk: $subjectPk, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('teacher: $teacher, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('credits: $credits, ')
          ..write('order: $order, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subjectPk, name, code, teacher, colorHex,
      icon, credits, order, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.subjectPk == this.subjectPk &&
          other.name == this.name &&
          other.code == this.code &&
          other.teacher == this.teacher &&
          other.colorHex == this.colorHex &&
          other.icon == this.icon &&
          other.credits == this.credits &&
          other.order == this.order &&
          other.dateTimeModified == this.dateTimeModified);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<String> subjectPk;
  final Value<String> name;
  final Value<String> code;
  final Value<String?> teacher;
  final Value<String> colorHex;
  final Value<String> icon;
  final Value<int> credits;
  final Value<int> order;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.subjectPk = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.teacher = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.credits = const Value.absent(),
    this.order = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String subjectPk,
    required String name,
    required String code,
    this.teacher = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.credits = const Value.absent(),
    this.order = const Value.absent(),
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : subjectPk = Value(subjectPk),
        name = Value(name),
        code = Value(code),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<Subject> custom({
    Expression<String>? subjectPk,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? teacher,
    Expression<String>? colorHex,
    Expression<String>? icon,
    Expression<int>? credits,
    Expression<int>? order,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectPk != null) 'subject_pk': subjectPk,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (teacher != null) 'teacher': teacher,
      if (colorHex != null) 'color_hex': colorHex,
      if (icon != null) 'icon': icon,
      if (credits != null) 'credits': credits,
      if (order != null) 'order': order,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith(
      {Value<String>? subjectPk,
      Value<String>? name,
      Value<String>? code,
      Value<String?>? teacher,
      Value<String>? colorHex,
      Value<String>? icon,
      Value<int>? credits,
      Value<int>? order,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return SubjectsCompanion(
      subjectPk: subjectPk ?? this.subjectPk,
      name: name ?? this.name,
      code: code ?? this.code,
      teacher: teacher ?? this.teacher,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      credits: credits ?? this.credits,
      order: order ?? this.order,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectPk.present) {
      map['subject_pk'] = Variable<String>(subjectPk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (credits.present) {
      map['credits'] = Variable<int>(credits.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('subjectPk: $subjectPk, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('teacher: $teacher, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('credits: $credits, ')
          ..write('order: $order, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocTypesTable extends DocTypes with TableInfo<$DocTypesTable, DocType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _docTypePkMeta =
      const VerificationMeta('docTypePk');
  @override
  late final GeneratedColumn<String> docTypePk = GeneratedColumn<String>(
      'doc_type_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#10b981'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('file'));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [docTypePk, name, colorHex, icon, order, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'doc_types';
  @override
  VerificationContext validateIntegrity(Insertable<DocType> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('doc_type_pk')) {
      context.handle(
          _docTypePkMeta,
          docTypePk.isAcceptableOrUnknown(
              data['doc_type_pk']!, _docTypePkMeta));
    } else if (isInserting) {
      context.missing(_docTypePkMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {docTypePk};
  @override
  DocType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocType(
      docTypePk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doc_type_pk'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $DocTypesTable createAlias(String alias) {
    return $DocTypesTable(attachedDatabase, alias);
  }
}

class DocType extends DataClass implements Insertable<DocType> {
  final String docTypePk;
  final String name;
  final String colorHex;
  final String icon;
  final int order;
  final DateTime dateTimeModified;
  const DocType(
      {required this.docTypePk,
      required this.name,
      required this.colorHex,
      required this.icon,
      required this.order,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['doc_type_pk'] = Variable<String>(docTypePk);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    map['icon'] = Variable<String>(icon);
    map['order'] = Variable<int>(order);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DocTypesCompanion toCompanion(bool nullToAbsent) {
    return DocTypesCompanion(
      docTypePk: Value(docTypePk),
      name: Value(name),
      colorHex: Value(colorHex),
      icon: Value(icon),
      order: Value(order),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory DocType.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocType(
      docTypePk: serializer.fromJson<String>(json['docTypePk']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      icon: serializer.fromJson<String>(json['icon']),
      order: serializer.fromJson<int>(json['order']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'docTypePk': serializer.toJson<String>(docTypePk),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'icon': serializer.toJson<String>(icon),
      'order': serializer.toJson<int>(order),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  DocType copyWith(
          {String? docTypePk,
          String? name,
          String? colorHex,
          String? icon,
          int? order,
          DateTime? dateTimeModified}) =>
      DocType(
        docTypePk: docTypePk ?? this.docTypePk,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        icon: icon ?? this.icon,
        order: order ?? this.order,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('DocType(')
          ..write('docTypePk: $docTypePk, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('order: $order, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(docTypePk, name, colorHex, icon, order, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocType &&
          other.docTypePk == this.docTypePk &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.icon == this.icon &&
          other.order == this.order &&
          other.dateTimeModified == this.dateTimeModified);
}

class DocTypesCompanion extends UpdateCompanion<DocType> {
  final Value<String> docTypePk;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String> icon;
  final Value<int> order;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DocTypesCompanion({
    this.docTypePk = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.order = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocTypesCompanion.insert({
    required String docTypePk,
    required String name,
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.order = const Value.absent(),
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : docTypePk = Value(docTypePk),
        name = Value(name),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<DocType> custom({
    Expression<String>? docTypePk,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? icon,
    Expression<int>? order,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (docTypePk != null) 'doc_type_pk': docTypePk,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (icon != null) 'icon': icon,
      if (order != null) 'order': order,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocTypesCompanion copyWith(
      {Value<String>? docTypePk,
      Value<String>? name,
      Value<String>? colorHex,
      Value<String>? icon,
      Value<int>? order,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return DocTypesCompanion(
      docTypePk: docTypePk ?? this.docTypePk,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (docTypePk.present) {
      map['doc_type_pk'] = Variable<String>(docTypePk.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocTypesCompanion(')
          ..write('docTypePk: $docTypePk, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('order: $order, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentPkMeta =
      const VerificationMeta('documentPk');
  @override
  late final GeneratedColumn<String> documentPk = GeneratedColumn<String>(
      'document_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 250),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localFilePathMeta =
      const VerificationMeta('localFilePath');
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
      'local_file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _externalUrlMeta =
      const VerificationMeta('externalUrl');
  @override
  late final GeneratedColumn<String> externalUrl = GeneratedColumn<String>(
      'external_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subjectFkMeta =
      const VerificationMeta('subjectFk');
  @override
  late final GeneratedColumn<String> subjectFk = GeneratedColumn<String>(
      'subject_fk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _docTypeFkMeta =
      const VerificationMeta('docTypeFk');
  @override
  late final GeneratedColumn<String> docTypeFk = GeneratedColumn<String>(
      'doc_type_fk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dateTimeCreatedMeta =
      const VerificationMeta('dateTimeCreated');
  @override
  late final GeneratedColumn<DateTime> dateTimeCreated =
      GeneratedColumn<DateTime>('date_time_created', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        documentPk,
        title,
        note,
        localFilePath,
        externalUrl,
        subjectFk,
        docTypeFk,
        dueDate,
        status,
        isPinned,
        dateTimeCreated,
        dateTimeModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(Insertable<Document> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_pk')) {
      context.handle(
          _documentPkMeta,
          documentPk.isAcceptableOrUnknown(
              data['document_pk']!, _documentPkMeta));
    } else if (isInserting) {
      context.missing(_documentPkMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
          _localFilePathMeta,
          localFilePath.isAcceptableOrUnknown(
              data['local_file_path']!, _localFilePathMeta));
    }
    if (data.containsKey('external_url')) {
      context.handle(
          _externalUrlMeta,
          externalUrl.isAcceptableOrUnknown(
              data['external_url']!, _externalUrlMeta));
    }
    if (data.containsKey('subject_fk')) {
      context.handle(_subjectFkMeta,
          subjectFk.isAcceptableOrUnknown(data['subject_fk']!, _subjectFkMeta));
    } else if (isInserting) {
      context.missing(_subjectFkMeta);
    }
    if (data.containsKey('doc_type_fk')) {
      context.handle(
          _docTypeFkMeta,
          docTypeFk.isAcceptableOrUnknown(
              data['doc_type_fk']!, _docTypeFkMeta));
    } else if (isInserting) {
      context.missing(_docTypeFkMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('date_time_created')) {
      context.handle(
          _dateTimeCreatedMeta,
          dateTimeCreated.isAcceptableOrUnknown(
              data['date_time_created']!, _dateTimeCreatedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeCreatedMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentPk};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      documentPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_pk'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      localFilePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_file_path']),
      externalUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_url']),
      subjectFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_fk'])!,
      docTypeFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doc_type_fk'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      dateTimeCreated: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class Document extends DataClass implements Insertable<Document> {
  final String documentPk;
  final String title;
  final String? note;
  final String? localFilePath;
  final String? externalUrl;
  final String subjectFk;
  final String docTypeFk;
  final DateTime? dueDate;
  final int status;
  final bool isPinned;
  final DateTime dateTimeCreated;
  final DateTime dateTimeModified;
  const Document(
      {required this.documentPk,
      required this.title,
      this.note,
      this.localFilePath,
      this.externalUrl,
      required this.subjectFk,
      required this.docTypeFk,
      this.dueDate,
      required this.status,
      required this.isPinned,
      required this.dateTimeCreated,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_pk'] = Variable<String>(documentPk);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || localFilePath != null) {
      map['local_file_path'] = Variable<String>(localFilePath);
    }
    if (!nullToAbsent || externalUrl != null) {
      map['external_url'] = Variable<String>(externalUrl);
    }
    map['subject_fk'] = Variable<String>(subjectFk);
    map['doc_type_fk'] = Variable<String>(docTypeFk);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['status'] = Variable<int>(status);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['date_time_created'] = Variable<DateTime>(dateTimeCreated);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      documentPk: Value(documentPk),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      localFilePath: localFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localFilePath),
      externalUrl: externalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(externalUrl),
      subjectFk: Value(subjectFk),
      docTypeFk: Value(docTypeFk),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      status: Value(status),
      isPinned: Value(isPinned),
      dateTimeCreated: Value(dateTimeCreated),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory Document.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      documentPk: serializer.fromJson<String>(json['documentPk']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      localFilePath: serializer.fromJson<String?>(json['localFilePath']),
      externalUrl: serializer.fromJson<String?>(json['externalUrl']),
      subjectFk: serializer.fromJson<String>(json['subjectFk']),
      docTypeFk: serializer.fromJson<String>(json['docTypeFk']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      status: serializer.fromJson<int>(json['status']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      dateTimeCreated: serializer.fromJson<DateTime>(json['dateTimeCreated']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentPk': serializer.toJson<String>(documentPk),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'localFilePath': serializer.toJson<String?>(localFilePath),
      'externalUrl': serializer.toJson<String?>(externalUrl),
      'subjectFk': serializer.toJson<String>(subjectFk),
      'docTypeFk': serializer.toJson<String>(docTypeFk),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'status': serializer.toJson<int>(status),
      'isPinned': serializer.toJson<bool>(isPinned),
      'dateTimeCreated': serializer.toJson<DateTime>(dateTimeCreated),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  Document copyWith(
          {String? documentPk,
          String? title,
          Value<String?> note = const Value.absent(),
          Value<String?> localFilePath = const Value.absent(),
          Value<String?> externalUrl = const Value.absent(),
          String? subjectFk,
          String? docTypeFk,
          Value<DateTime?> dueDate = const Value.absent(),
          int? status,
          bool? isPinned,
          DateTime? dateTimeCreated,
          DateTime? dateTimeModified}) =>
      Document(
        documentPk: documentPk ?? this.documentPk,
        title: title ?? this.title,
        note: note.present ? note.value : this.note,
        localFilePath:
            localFilePath.present ? localFilePath.value : this.localFilePath,
        externalUrl: externalUrl.present ? externalUrl.value : this.externalUrl,
        subjectFk: subjectFk ?? this.subjectFk,
        docTypeFk: docTypeFk ?? this.docTypeFk,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        status: status ?? this.status,
        isPinned: isPinned ?? this.isPinned,
        dateTimeCreated: dateTimeCreated ?? this.dateTimeCreated,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('documentPk: $documentPk, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('docTypeFk: $docTypeFk, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('isPinned: $isPinned, ')
          ..write('dateTimeCreated: $dateTimeCreated, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      documentPk,
      title,
      note,
      localFilePath,
      externalUrl,
      subjectFk,
      docTypeFk,
      dueDate,
      status,
      isPinned,
      dateTimeCreated,
      dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.documentPk == this.documentPk &&
          other.title == this.title &&
          other.note == this.note &&
          other.localFilePath == this.localFilePath &&
          other.externalUrl == this.externalUrl &&
          other.subjectFk == this.subjectFk &&
          other.docTypeFk == this.docTypeFk &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.isPinned == this.isPinned &&
          other.dateTimeCreated == this.dateTimeCreated &&
          other.dateTimeModified == this.dateTimeModified);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> documentPk;
  final Value<String> title;
  final Value<String?> note;
  final Value<String?> localFilePath;
  final Value<String?> externalUrl;
  final Value<String> subjectFk;
  final Value<String> docTypeFk;
  final Value<DateTime?> dueDate;
  final Value<int> status;
  final Value<bool> isPinned;
  final Value<DateTime> dateTimeCreated;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.documentPk = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.externalUrl = const Value.absent(),
    this.subjectFk = const Value.absent(),
    this.docTypeFk = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.dateTimeCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String documentPk,
    required String title,
    this.note = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.externalUrl = const Value.absent(),
    required String subjectFk,
    required String docTypeFk,
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.isPinned = const Value.absent(),
    required DateTime dateTimeCreated,
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : documentPk = Value(documentPk),
        title = Value(title),
        subjectFk = Value(subjectFk),
        docTypeFk = Value(docTypeFk),
        dateTimeCreated = Value(dateTimeCreated),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<Document> custom({
    Expression<String>? documentPk,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? localFilePath,
    Expression<String>? externalUrl,
    Expression<String>? subjectFk,
    Expression<String>? docTypeFk,
    Expression<DateTime>? dueDate,
    Expression<int>? status,
    Expression<bool>? isPinned,
    Expression<DateTime>? dateTimeCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentPk != null) 'document_pk': documentPk,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (externalUrl != null) 'external_url': externalUrl,
      if (subjectFk != null) 'subject_fk': subjectFk,
      if (docTypeFk != null) 'doc_type_fk': docTypeFk,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (isPinned != null) 'is_pinned': isPinned,
      if (dateTimeCreated != null) 'date_time_created': dateTimeCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith(
      {Value<String>? documentPk,
      Value<String>? title,
      Value<String?>? note,
      Value<String?>? localFilePath,
      Value<String?>? externalUrl,
      Value<String>? subjectFk,
      Value<String>? docTypeFk,
      Value<DateTime?>? dueDate,
      Value<int>? status,
      Value<bool>? isPinned,
      Value<DateTime>? dateTimeCreated,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return DocumentsCompanion(
      documentPk: documentPk ?? this.documentPk,
      title: title ?? this.title,
      note: note ?? this.note,
      localFilePath: localFilePath ?? this.localFilePath,
      externalUrl: externalUrl ?? this.externalUrl,
      subjectFk: subjectFk ?? this.subjectFk,
      docTypeFk: docTypeFk ?? this.docTypeFk,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      dateTimeCreated: dateTimeCreated ?? this.dateTimeCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentPk.present) {
      map['document_pk'] = Variable<String>(documentPk.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (externalUrl.present) {
      map['external_url'] = Variable<String>(externalUrl.value);
    }
    if (subjectFk.present) {
      map['subject_fk'] = Variable<String>(subjectFk.value);
    }
    if (docTypeFk.present) {
      map['doc_type_fk'] = Variable<String>(docTypeFk.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (dateTimeCreated.present) {
      map['date_time_created'] = Variable<DateTime>(dateTimeCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('documentPk: $documentPk, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('docTypeFk: $docTypeFk, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('isPinned: $isPinned, ')
          ..write('dateTimeCreated: $dateTimeCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyGoalsTable extends StudyGoals
    with TableInfo<$StudyGoalsTable, StudyGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _goalPkMeta = const VerificationMeta('goalPk');
  @override
  late final GeneratedColumn<String> goalPk = GeneratedColumn<String>(
      'goal_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 250),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _subjectFkMeta =
      const VerificationMeta('subjectFk');
  @override
  late final GeneratedColumn<String> subjectFk = GeneratedColumn<String>(
      'subject_fk', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetCountMeta =
      const VerificationMeta('targetCount');
  @override
  late final GeneratedColumn<int> targetCount = GeneratedColumn<int>(
      'target_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _completedCountMeta =
      const VerificationMeta('completedCount');
  @override
  late final GeneratedColumn<int> completedCount = GeneratedColumn<int>(
      'completed_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        goalPk,
        title,
        subjectFk,
        targetCount,
        completedCount,
        dueDate,
        dateTimeModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_goals';
  @override
  VerificationContext validateIntegrity(Insertable<StudyGoal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('goal_pk')) {
      context.handle(_goalPkMeta,
          goalPk.isAcceptableOrUnknown(data['goal_pk']!, _goalPkMeta));
    } else if (isInserting) {
      context.missing(_goalPkMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject_fk')) {
      context.handle(_subjectFkMeta,
          subjectFk.isAcceptableOrUnknown(data['subject_fk']!, _subjectFkMeta));
    }
    if (data.containsKey('target_count')) {
      context.handle(
          _targetCountMeta,
          targetCount.isAcceptableOrUnknown(
              data['target_count']!, _targetCountMeta));
    }
    if (data.containsKey('completed_count')) {
      context.handle(
          _completedCountMeta,
          completedCount.isAcceptableOrUnknown(
              data['completed_count']!, _completedCountMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {goalPk};
  @override
  StudyGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyGoal(
      goalPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_pk'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      subjectFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_fk']),
      targetCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_count'])!,
      completedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_count'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $StudyGoalsTable createAlias(String alias) {
    return $StudyGoalsTable(attachedDatabase, alias);
  }
}

class StudyGoal extends DataClass implements Insertable<StudyGoal> {
  final String goalPk;
  final String title;
  final String? subjectFk;
  final int targetCount;
  final int completedCount;
  final DateTime? dueDate;
  final DateTime dateTimeModified;
  const StudyGoal(
      {required this.goalPk,
      required this.title,
      this.subjectFk,
      required this.targetCount,
      required this.completedCount,
      this.dueDate,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['goal_pk'] = Variable<String>(goalPk);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subjectFk != null) {
      map['subject_fk'] = Variable<String>(subjectFk);
    }
    map['target_count'] = Variable<int>(targetCount);
    map['completed_count'] = Variable<int>(completedCount);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  StudyGoalsCompanion toCompanion(bool nullToAbsent) {
    return StudyGoalsCompanion(
      goalPk: Value(goalPk),
      title: Value(title),
      subjectFk: subjectFk == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectFk),
      targetCount: Value(targetCount),
      completedCount: Value(completedCount),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory StudyGoal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyGoal(
      goalPk: serializer.fromJson<String>(json['goalPk']),
      title: serializer.fromJson<String>(json['title']),
      subjectFk: serializer.fromJson<String?>(json['subjectFk']),
      targetCount: serializer.fromJson<int>(json['targetCount']),
      completedCount: serializer.fromJson<int>(json['completedCount']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'goalPk': serializer.toJson<String>(goalPk),
      'title': serializer.toJson<String>(title),
      'subjectFk': serializer.toJson<String?>(subjectFk),
      'targetCount': serializer.toJson<int>(targetCount),
      'completedCount': serializer.toJson<int>(completedCount),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  StudyGoal copyWith(
          {String? goalPk,
          String? title,
          Value<String?> subjectFk = const Value.absent(),
          int? targetCount,
          int? completedCount,
          Value<DateTime?> dueDate = const Value.absent(),
          DateTime? dateTimeModified}) =>
      StudyGoal(
        goalPk: goalPk ?? this.goalPk,
        title: title ?? this.title,
        subjectFk: subjectFk.present ? subjectFk.value : this.subjectFk,
        targetCount: targetCount ?? this.targetCount,
        completedCount: completedCount ?? this.completedCount,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('StudyGoal(')
          ..write('goalPk: $goalPk, ')
          ..write('title: $title, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('targetCount: $targetCount, ')
          ..write('completedCount: $completedCount, ')
          ..write('dueDate: $dueDate, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(goalPk, title, subjectFk, targetCount,
      completedCount, dueDate, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyGoal &&
          other.goalPk == this.goalPk &&
          other.title == this.title &&
          other.subjectFk == this.subjectFk &&
          other.targetCount == this.targetCount &&
          other.completedCount == this.completedCount &&
          other.dueDate == this.dueDate &&
          other.dateTimeModified == this.dateTimeModified);
}

class StudyGoalsCompanion extends UpdateCompanion<StudyGoal> {
  final Value<String> goalPk;
  final Value<String> title;
  final Value<String?> subjectFk;
  final Value<int> targetCount;
  final Value<int> completedCount;
  final Value<DateTime?> dueDate;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const StudyGoalsCompanion({
    this.goalPk = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectFk = const Value.absent(),
    this.targetCount = const Value.absent(),
    this.completedCount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyGoalsCompanion.insert({
    required String goalPk,
    required String title,
    this.subjectFk = const Value.absent(),
    this.targetCount = const Value.absent(),
    this.completedCount = const Value.absent(),
    this.dueDate = const Value.absent(),
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : goalPk = Value(goalPk),
        title = Value(title),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<StudyGoal> custom({
    Expression<String>? goalPk,
    Expression<String>? title,
    Expression<String>? subjectFk,
    Expression<int>? targetCount,
    Expression<int>? completedCount,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (goalPk != null) 'goal_pk': goalPk,
      if (title != null) 'title': title,
      if (subjectFk != null) 'subject_fk': subjectFk,
      if (targetCount != null) 'target_count': targetCount,
      if (completedCount != null) 'completed_count': completedCount,
      if (dueDate != null) 'due_date': dueDate,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyGoalsCompanion copyWith(
      {Value<String>? goalPk,
      Value<String>? title,
      Value<String?>? subjectFk,
      Value<int>? targetCount,
      Value<int>? completedCount,
      Value<DateTime?>? dueDate,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return StudyGoalsCompanion(
      goalPk: goalPk ?? this.goalPk,
      title: title ?? this.title,
      subjectFk: subjectFk ?? this.subjectFk,
      targetCount: targetCount ?? this.targetCount,
      completedCount: completedCount ?? this.completedCount,
      dueDate: dueDate ?? this.dueDate,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (goalPk.present) {
      map['goal_pk'] = Variable<String>(goalPk.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subjectFk.present) {
      map['subject_fk'] = Variable<String>(subjectFk.value);
    }
    if (targetCount.present) {
      map['target_count'] = Variable<int>(targetCount.value);
    }
    if (completedCount.present) {
      map['completed_count'] = Variable<int>(completedCount.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyGoalsCompanion(')
          ..write('goalPk: $goalPk, ')
          ..write('title: $title, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('targetCount: $targetCount, ')
          ..write('completedCount: $completedCount, ')
          ..write('dueDate: $dueDate, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeleteLogsTable extends DeleteLogs
    with TableInfo<$DeleteLogsTable, DeleteLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeleteLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deleteLogPkMeta =
      const VerificationMeta('deleteLogPk');
  @override
  late final GeneratedColumn<String> deleteLogPk = GeneratedColumn<String>(
      'delete_log_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entryPkMeta =
      const VerificationMeta('entryPk');
  @override
  late final GeneratedColumn<String> entryPk = GeneratedColumn<String>(
      'entry_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [deleteLogPk, type, entryPk, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delete_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DeleteLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('delete_log_pk')) {
      context.handle(
          _deleteLogPkMeta,
          deleteLogPk.isAcceptableOrUnknown(
              data['delete_log_pk']!, _deleteLogPkMeta));
    } else if (isInserting) {
      context.missing(_deleteLogPkMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('entry_pk')) {
      context.handle(_entryPkMeta,
          entryPk.isAcceptableOrUnknown(data['entry_pk']!, _entryPkMeta));
    } else if (isInserting) {
      context.missing(_entryPkMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deleteLogPk};
  @override
  DeleteLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeleteLog(
      deleteLogPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delete_log_pk'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      entryPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_pk'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $DeleteLogsTable createAlias(String alias) {
    return $DeleteLogsTable(attachedDatabase, alias);
  }
}

class DeleteLog extends DataClass implements Insertable<DeleteLog> {
  final String deleteLogPk;
  final String type;
  final String entryPk;
  final DateTime dateTimeModified;
  const DeleteLog(
      {required this.deleteLogPk,
      required this.type,
      required this.entryPk,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['delete_log_pk'] = Variable<String>(deleteLogPk);
    map['type'] = Variable<String>(type);
    map['entry_pk'] = Variable<String>(entryPk);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DeleteLogsCompanion toCompanion(bool nullToAbsent) {
    return DeleteLogsCompanion(
      deleteLogPk: Value(deleteLogPk),
      type: Value(type),
      entryPk: Value(entryPk),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory DeleteLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeleteLog(
      deleteLogPk: serializer.fromJson<String>(json['deleteLogPk']),
      type: serializer.fromJson<String>(json['type']),
      entryPk: serializer.fromJson<String>(json['entryPk']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deleteLogPk': serializer.toJson<String>(deleteLogPk),
      'type': serializer.toJson<String>(type),
      'entryPk': serializer.toJson<String>(entryPk),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  DeleteLog copyWith(
          {String? deleteLogPk,
          String? type,
          String? entryPk,
          DateTime? dateTimeModified}) =>
      DeleteLog(
        deleteLogPk: deleteLogPk ?? this.deleteLogPk,
        type: type ?? this.type,
        entryPk: entryPk ?? this.entryPk,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  @override
  String toString() {
    return (StringBuffer('DeleteLog(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('type: $type, ')
          ..write('entryPk: $entryPk, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deleteLogPk, type, entryPk, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeleteLog &&
          other.deleteLogPk == this.deleteLogPk &&
          other.type == this.type &&
          other.entryPk == this.entryPk &&
          other.dateTimeModified == this.dateTimeModified);
}

class DeleteLogsCompanion extends UpdateCompanion<DeleteLog> {
  final Value<String> deleteLogPk;
  final Value<String> type;
  final Value<String> entryPk;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DeleteLogsCompanion({
    this.deleteLogPk = const Value.absent(),
    this.type = const Value.absent(),
    this.entryPk = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeleteLogsCompanion.insert({
    required String deleteLogPk,
    required String type,
    required String entryPk,
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : deleteLogPk = Value(deleteLogPk),
        type = Value(type),
        entryPk = Value(entryPk),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<DeleteLog> custom({
    Expression<String>? deleteLogPk,
    Expression<String>? type,
    Expression<String>? entryPk,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deleteLogPk != null) 'delete_log_pk': deleteLogPk,
      if (type != null) 'type': type,
      if (entryPk != null) 'entry_pk': entryPk,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeleteLogsCompanion copyWith(
      {Value<String>? deleteLogPk,
      Value<String>? type,
      Value<String>? entryPk,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return DeleteLogsCompanion(
      deleteLogPk: deleteLogPk ?? this.deleteLogPk,
      type: type ?? this.type,
      entryPk: entryPk ?? this.entryPk,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deleteLogPk.present) {
      map['delete_log_pk'] = Variable<String>(deleteLogPk.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (entryPk.present) {
      map['entry_pk'] = Variable<String>(entryPk.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeleteLogsCompanion(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('type: $type, ')
          ..write('entryPk: $entryPk, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingsPkMeta =
      const VerificationMeta('settingsPk');
  @override
  late final GeneratedColumn<String> settingsPk = GeneratedColumn<String>(
      'settings_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _settingsJSONMeta =
      const VerificationMeta('settingsJSON');
  @override
  late final GeneratedColumn<String> settingsJSON = GeneratedColumn<String>(
      'settings_j_s_o_n', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [settingsPk, settingsJSON, dateCreated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('settings_pk')) {
      context.handle(
          _settingsPkMeta,
          settingsPk.isAcceptableOrUnknown(
              data['settings_pk']!, _settingsPkMeta));
    } else if (isInserting) {
      context.missing(_settingsPkMeta);
    }
    if (data.containsKey('settings_j_s_o_n')) {
      context.handle(
          _settingsJSONMeta,
          settingsJSON.isAcceptableOrUnknown(
              data['settings_j_s_o_n']!, _settingsJSONMeta));
    } else if (isInserting) {
      context.missing(_settingsJSONMeta);
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    } else if (isInserting) {
      context.missing(_dateCreatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingsPk};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      settingsPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}settings_pk'])!,
      settingsJSON: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}settings_j_s_o_n'])!,
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String settingsPk;
  final String settingsJSON;
  final DateTime dateCreated;
  const AppSetting(
      {required this.settingsPk,
      required this.settingsJSON,
      required this.dateCreated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['settings_pk'] = Variable<String>(settingsPk);
    map['settings_j_s_o_n'] = Variable<String>(settingsJSON);
    map['date_created'] = Variable<DateTime>(dateCreated);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingsPk: Value(settingsPk),
      settingsJSON: Value(settingsJSON),
      dateCreated: Value(dateCreated),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      settingsPk: serializer.fromJson<String>(json['settingsPk']),
      settingsJSON: serializer.fromJson<String>(json['settingsJSON']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingsPk': serializer.toJson<String>(settingsPk),
      'settingsJSON': serializer.toJson<String>(settingsJSON),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
    };
  }

  AppSetting copyWith(
          {String? settingsPk, String? settingsJSON, DateTime? dateCreated}) =>
      AppSetting(
        settingsPk: settingsPk ?? this.settingsPk,
        settingsJSON: settingsJSON ?? this.settingsJSON,
        dateCreated: dateCreated ?? this.dateCreated,
      );
  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('settingsPk: $settingsPk, ')
          ..write('settingsJSON: $settingsJSON, ')
          ..write('dateCreated: $dateCreated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingsPk, settingsJSON, dateCreated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.settingsPk == this.settingsPk &&
          other.settingsJSON == this.settingsJSON &&
          other.dateCreated == this.dateCreated);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> settingsPk;
  final Value<String> settingsJSON;
  final Value<DateTime> dateCreated;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingsPk = const Value.absent(),
    this.settingsJSON = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingsPk,
    required String settingsJSON,
    required DateTime dateCreated,
    this.rowid = const Value.absent(),
  })  : settingsPk = Value(settingsPk),
        settingsJSON = Value(settingsJSON),
        dateCreated = Value(dateCreated);
  static Insertable<AppSetting> custom({
    Expression<String>? settingsPk,
    Expression<String>? settingsJSON,
    Expression<DateTime>? dateCreated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingsPk != null) 'settings_pk': settingsPk,
      if (settingsJSON != null) 'settings_j_s_o_n': settingsJSON,
      if (dateCreated != null) 'date_created': dateCreated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? settingsPk,
      Value<String>? settingsJSON,
      Value<DateTime>? dateCreated,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      settingsPk: settingsPk ?? this.settingsPk,
      settingsJSON: settingsJSON ?? this.settingsJSON,
      dateCreated: dateCreated ?? this.dateCreated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingsPk.present) {
      map['settings_pk'] = Variable<String>(settingsPk.value);
    }
    if (settingsJSON.present) {
      map['settings_j_s_o_n'] = Variable<String>(settingsJSON.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingsPk: $settingsPk, ')
          ..write('settingsJSON: $settingsJSON, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$StudyDatabase extends GeneratedDatabase {
  _$StudyDatabase(QueryExecutor e) : super(e);
  _$StudyDatabaseManager get managers => _$StudyDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $DocTypesTable docTypes = $DocTypesTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $StudyGoalsTable studyGoals = $StudyGoalsTable(this);
  late final $DeleteLogsTable deleteLogs = $DeleteLogsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final SubjectsDao subjectsDao = SubjectsDao(this as StudyDatabase);
  late final DocTypesDao docTypesDao = DocTypesDao(this as StudyDatabase);
  late final DocumentsDao documentsDao = DocumentsDao(this as StudyDatabase);
  late final StudyGoalsDao studyGoalsDao = StudyGoalsDao(this as StudyDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [subjects, docTypes, documents, studyGoals, deleteLogs, appSettings];
}

typedef $$SubjectsTableInsertCompanionBuilder = SubjectsCompanion Function({
  required String subjectPk,
  required String name,
  required String code,
  Value<String?> teacher,
  Value<String> colorHex,
  Value<String> icon,
  Value<int> credits,
  Value<int> order,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> subjectPk,
  Value<String> name,
  Value<String> code,
  Value<String?> teacher,
  Value<String> colorHex,
  Value<String> icon,
  Value<int> credits,
  Value<int> order,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$SubjectsTableTableManager extends RootTableManager<
    _$StudyDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableProcessedTableManager,
    $$SubjectsTableInsertCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder> {
  $$SubjectsTableTableManager(_$StudyDatabase db, $SubjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SubjectsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SubjectsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$SubjectsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> subjectPk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String?> teacher = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> credits = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion(
            subjectPk: subjectPk,
            name: name,
            code: code,
            teacher: teacher,
            colorHex: colorHex,
            icon: icon,
            credits: credits,
            order: order,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String subjectPk,
            required String name,
            required String code,
            Value<String?> teacher = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> credits = const Value.absent(),
            Value<int> order = const Value.absent(),
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion.insert(
            subjectPk: subjectPk,
            name: name,
            code: code,
            teacher: teacher,
            colorHex: colorHex,
            icon: icon,
            credits: credits,
            order: order,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$SubjectsTableProcessedTableManager extends ProcessedTableManager<
    _$StudyDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableProcessedTableManager,
    $$SubjectsTableInsertCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder> {
  $$SubjectsTableProcessedTableManager(super.$state);
}

class $$SubjectsTableFilterComposer
    extends FilterComposer<_$StudyDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer(super.$state);
  ColumnFilters<String> get subjectPk => $state.composableBuilder(
      column: $state.table.subjectPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teacher => $state.composableBuilder(
      column: $state.table.teacher,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get credits => $state.composableBuilder(
      column: $state.table.credits,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SubjectsTableOrderingComposer
    extends OrderingComposer<_$StudyDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get subjectPk => $state.composableBuilder(
      column: $state.table.subjectPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teacher => $state.composableBuilder(
      column: $state.table.teacher,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get credits => $state.composableBuilder(
      column: $state.table.credits,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DocTypesTableInsertCompanionBuilder = DocTypesCompanion Function({
  required String docTypePk,
  required String name,
  Value<String> colorHex,
  Value<String> icon,
  Value<int> order,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$DocTypesTableUpdateCompanionBuilder = DocTypesCompanion Function({
  Value<String> docTypePk,
  Value<String> name,
  Value<String> colorHex,
  Value<String> icon,
  Value<int> order,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$DocTypesTableTableManager extends RootTableManager<
    _$StudyDatabase,
    $DocTypesTable,
    DocType,
    $$DocTypesTableFilterComposer,
    $$DocTypesTableOrderingComposer,
    $$DocTypesTableProcessedTableManager,
    $$DocTypesTableInsertCompanionBuilder,
    $$DocTypesTableUpdateCompanionBuilder> {
  $$DocTypesTableTableManager(_$StudyDatabase db, $DocTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DocTypesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DocTypesTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$DocTypesTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> docTypePk = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocTypesCompanion(
            docTypePk: docTypePk,
            name: name,
            colorHex: colorHex,
            icon: icon,
            order: order,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String docTypePk,
            required String name,
            Value<String> colorHex = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> order = const Value.absent(),
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocTypesCompanion.insert(
            docTypePk: docTypePk,
            name: name,
            colorHex: colorHex,
            icon: icon,
            order: order,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$DocTypesTableProcessedTableManager extends ProcessedTableManager<
    _$StudyDatabase,
    $DocTypesTable,
    DocType,
    $$DocTypesTableFilterComposer,
    $$DocTypesTableOrderingComposer,
    $$DocTypesTableProcessedTableManager,
    $$DocTypesTableInsertCompanionBuilder,
    $$DocTypesTableUpdateCompanionBuilder> {
  $$DocTypesTableProcessedTableManager(super.$state);
}

class $$DocTypesTableFilterComposer
    extends FilterComposer<_$StudyDatabase, $DocTypesTable> {
  $$DocTypesTableFilterComposer(super.$state);
  ColumnFilters<String> get docTypePk => $state.composableBuilder(
      column: $state.table.docTypePk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DocTypesTableOrderingComposer
    extends OrderingComposer<_$StudyDatabase, $DocTypesTable> {
  $$DocTypesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get docTypePk => $state.composableBuilder(
      column: $state.table.docTypePk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DocumentsTableInsertCompanionBuilder = DocumentsCompanion Function({
  required String documentPk,
  required String title,
  Value<String?> note,
  Value<String?> localFilePath,
  Value<String?> externalUrl,
  required String subjectFk,
  required String docTypeFk,
  Value<DateTime?> dueDate,
  Value<int> status,
  Value<bool> isPinned,
  required DateTime dateTimeCreated,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> documentPk,
  Value<String> title,
  Value<String?> note,
  Value<String?> localFilePath,
  Value<String?> externalUrl,
  Value<String> subjectFk,
  Value<String> docTypeFk,
  Value<DateTime?> dueDate,
  Value<int> status,
  Value<bool> isPinned,
  Value<DateTime> dateTimeCreated,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$DocumentsTableTableManager extends RootTableManager<
    _$StudyDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableProcessedTableManager,
    $$DocumentsTableInsertCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder> {
  $$DocumentsTableTableManager(_$StudyDatabase db, $DocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DocumentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DocumentsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$DocumentsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> documentPk = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> localFilePath = const Value.absent(),
            Value<String?> externalUrl = const Value.absent(),
            Value<String> subjectFk = const Value.absent(),
            Value<String> docTypeFk = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<DateTime> dateTimeCreated = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion(
            documentPk: documentPk,
            title: title,
            note: note,
            localFilePath: localFilePath,
            externalUrl: externalUrl,
            subjectFk: subjectFk,
            docTypeFk: docTypeFk,
            dueDate: dueDate,
            status: status,
            isPinned: isPinned,
            dateTimeCreated: dateTimeCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String documentPk,
            required String title,
            Value<String?> note = const Value.absent(),
            Value<String?> localFilePath = const Value.absent(),
            Value<String?> externalUrl = const Value.absent(),
            required String subjectFk,
            required String docTypeFk,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            required DateTime dateTimeCreated,
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion.insert(
            documentPk: documentPk,
            title: title,
            note: note,
            localFilePath: localFilePath,
            externalUrl: externalUrl,
            subjectFk: subjectFk,
            docTypeFk: docTypeFk,
            dueDate: dueDate,
            status: status,
            isPinned: isPinned,
            dateTimeCreated: dateTimeCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$DocumentsTableProcessedTableManager extends ProcessedTableManager<
    _$StudyDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableProcessedTableManager,
    $$DocumentsTableInsertCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder> {
  $$DocumentsTableProcessedTableManager(super.$state);
}

class $$DocumentsTableFilterComposer
    extends FilterComposer<_$StudyDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer(super.$state);
  ColumnFilters<String> get documentPk => $state.composableBuilder(
      column: $state.table.documentPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localFilePath => $state.composableBuilder(
      column: $state.table.localFilePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get externalUrl => $state.composableBuilder(
      column: $state.table.externalUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subjectFk => $state.composableBuilder(
      column: $state.table.subjectFk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get docTypeFk => $state.composableBuilder(
      column: $state.table.docTypeFk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isPinned => $state.composableBuilder(
      column: $state.table.isPinned,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeCreated => $state.composableBuilder(
      column: $state.table.dateTimeCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DocumentsTableOrderingComposer
    extends OrderingComposer<_$StudyDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get documentPk => $state.composableBuilder(
      column: $state.table.documentPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localFilePath => $state.composableBuilder(
      column: $state.table.localFilePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get externalUrl => $state.composableBuilder(
      column: $state.table.externalUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subjectFk => $state.composableBuilder(
      column: $state.table.subjectFk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get docTypeFk => $state.composableBuilder(
      column: $state.table.docTypeFk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isPinned => $state.composableBuilder(
      column: $state.table.isPinned,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeCreated => $state.composableBuilder(
      column: $state.table.dateTimeCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$StudyGoalsTableInsertCompanionBuilder = StudyGoalsCompanion Function({
  required String goalPk,
  required String title,
  Value<String?> subjectFk,
  Value<int> targetCount,
  Value<int> completedCount,
  Value<DateTime?> dueDate,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$StudyGoalsTableUpdateCompanionBuilder = StudyGoalsCompanion Function({
  Value<String> goalPk,
  Value<String> title,
  Value<String?> subjectFk,
  Value<int> targetCount,
  Value<int> completedCount,
  Value<DateTime?> dueDate,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$StudyGoalsTableTableManager extends RootTableManager<
    _$StudyDatabase,
    $StudyGoalsTable,
    StudyGoal,
    $$StudyGoalsTableFilterComposer,
    $$StudyGoalsTableOrderingComposer,
    $$StudyGoalsTableProcessedTableManager,
    $$StudyGoalsTableInsertCompanionBuilder,
    $$StudyGoalsTableUpdateCompanionBuilder> {
  $$StudyGoalsTableTableManager(_$StudyDatabase db, $StudyGoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$StudyGoalsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$StudyGoalsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$StudyGoalsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> goalPk = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> subjectFk = const Value.absent(),
            Value<int> targetCount = const Value.absent(),
            Value<int> completedCount = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudyGoalsCompanion(
            goalPk: goalPk,
            title: title,
            subjectFk: subjectFk,
            targetCount: targetCount,
            completedCount: completedCount,
            dueDate: dueDate,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String goalPk,
            required String title,
            Value<String?> subjectFk = const Value.absent(),
            Value<int> targetCount = const Value.absent(),
            Value<int> completedCount = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              StudyGoalsCompanion.insert(
            goalPk: goalPk,
            title: title,
            subjectFk: subjectFk,
            targetCount: targetCount,
            completedCount: completedCount,
            dueDate: dueDate,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$StudyGoalsTableProcessedTableManager extends ProcessedTableManager<
    _$StudyDatabase,
    $StudyGoalsTable,
    StudyGoal,
    $$StudyGoalsTableFilterComposer,
    $$StudyGoalsTableOrderingComposer,
    $$StudyGoalsTableProcessedTableManager,
    $$StudyGoalsTableInsertCompanionBuilder,
    $$StudyGoalsTableUpdateCompanionBuilder> {
  $$StudyGoalsTableProcessedTableManager(super.$state);
}

class $$StudyGoalsTableFilterComposer
    extends FilterComposer<_$StudyDatabase, $StudyGoalsTable> {
  $$StudyGoalsTableFilterComposer(super.$state);
  ColumnFilters<String> get goalPk => $state.composableBuilder(
      column: $state.table.goalPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subjectFk => $state.composableBuilder(
      column: $state.table.subjectFk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get targetCount => $state.composableBuilder(
      column: $state.table.targetCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get completedCount => $state.composableBuilder(
      column: $state.table.completedCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$StudyGoalsTableOrderingComposer
    extends OrderingComposer<_$StudyDatabase, $StudyGoalsTable> {
  $$StudyGoalsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get goalPk => $state.composableBuilder(
      column: $state.table.goalPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subjectFk => $state.composableBuilder(
      column: $state.table.subjectFk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get targetCount => $state.composableBuilder(
      column: $state.table.targetCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get completedCount => $state.composableBuilder(
      column: $state.table.completedCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DeleteLogsTableInsertCompanionBuilder = DeleteLogsCompanion Function({
  required String deleteLogPk,
  required String type,
  required String entryPk,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$DeleteLogsTableUpdateCompanionBuilder = DeleteLogsCompanion Function({
  Value<String> deleteLogPk,
  Value<String> type,
  Value<String> entryPk,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$DeleteLogsTableTableManager extends RootTableManager<
    _$StudyDatabase,
    $DeleteLogsTable,
    DeleteLog,
    $$DeleteLogsTableFilterComposer,
    $$DeleteLogsTableOrderingComposer,
    $$DeleteLogsTableProcessedTableManager,
    $$DeleteLogsTableInsertCompanionBuilder,
    $$DeleteLogsTableUpdateCompanionBuilder> {
  $$DeleteLogsTableTableManager(_$StudyDatabase db, $DeleteLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DeleteLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DeleteLogsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$DeleteLogsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> deleteLogPk = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> entryPk = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeleteLogsCompanion(
            deleteLogPk: deleteLogPk,
            type: type,
            entryPk: entryPk,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String deleteLogPk,
            required String type,
            required String entryPk,
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              DeleteLogsCompanion.insert(
            deleteLogPk: deleteLogPk,
            type: type,
            entryPk: entryPk,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
        ));
}

class $$DeleteLogsTableProcessedTableManager extends ProcessedTableManager<
    _$StudyDatabase,
    $DeleteLogsTable,
    DeleteLog,
    $$DeleteLogsTableFilterComposer,
    $$DeleteLogsTableOrderingComposer,
    $$DeleteLogsTableProcessedTableManager,
    $$DeleteLogsTableInsertCompanionBuilder,
    $$DeleteLogsTableUpdateCompanionBuilder> {
  $$DeleteLogsTableProcessedTableManager(super.$state);
}

class $$DeleteLogsTableFilterComposer
    extends FilterComposer<_$StudyDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get deleteLogPk => $state.composableBuilder(
      column: $state.table.deleteLogPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entryPk => $state.composableBuilder(
      column: $state.table.entryPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DeleteLogsTableOrderingComposer
    extends OrderingComposer<_$StudyDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get deleteLogPk => $state.composableBuilder(
      column: $state.table.deleteLogPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entryPk => $state.composableBuilder(
      column: $state.table.entryPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateTimeModified => $state.composableBuilder(
      column: $state.table.dateTimeModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$AppSettingsTableInsertCompanionBuilder = AppSettingsCompanion
    Function({
  required String settingsPk,
  required String settingsJSON,
  required DateTime dateCreated,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> settingsPk,
  Value<String> settingsJSON,
  Value<DateTime> dateCreated,
  Value<int> rowid,
});

class $$AppSettingsTableTableManager extends RootTableManager<
    _$StudyDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableProcessedTableManager,
    $$AppSettingsTableInsertCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder> {
  $$AppSettingsTableTableManager(_$StudyDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AppSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AppSettingsTableOrderingComposer(ComposerState(db, table)),
          getChildManagerBuilder: (p) =>
              $$AppSettingsTableProcessedTableManager(p),
          getUpdateCompanionBuilder: ({
            Value<String> settingsPk = const Value.absent(),
            Value<String> settingsJSON = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            settingsPk: settingsPk,
            settingsJSON: settingsJSON,
            dateCreated: dateCreated,
            rowid: rowid,
          ),
          getInsertCompanionBuilder: ({
            required String settingsPk,
            required String settingsJSON,
            required DateTime dateCreated,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            settingsPk: settingsPk,
            settingsJSON: settingsJSON,
            dateCreated: dateCreated,
            rowid: rowid,
          ),
        ));
}

class $$AppSettingsTableProcessedTableManager extends ProcessedTableManager<
    _$StudyDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableProcessedTableManager,
    $$AppSettingsTableInsertCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder> {
  $$AppSettingsTableProcessedTableManager(super.$state);
}

class $$AppSettingsTableFilterComposer
    extends FilterComposer<_$StudyDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer(super.$state);
  ColumnFilters<String> get settingsPk => $state.composableBuilder(
      column: $state.table.settingsPk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get settingsJSON => $state.composableBuilder(
      column: $state.table.settingsJSON,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AppSettingsTableOrderingComposer
    extends OrderingComposer<_$StudyDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get settingsPk => $state.composableBuilder(
      column: $state.table.settingsPk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get settingsJSON => $state.composableBuilder(
      column: $state.table.settingsJSON,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateCreated => $state.composableBuilder(
      column: $state.table.dateCreated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class _$StudyDatabaseManager {
  final _$StudyDatabase _db;
  _$StudyDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$DocTypesTableTableManager get docTypes =>
      $$DocTypesTableTableManager(_db, _db.docTypes);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$StudyGoalsTableTableManager get studyGoals =>
      $$StudyGoalsTableTableManager(_db, _db.studyGoals);
  $$DeleteLogsTableTableManager get deleteLogs =>
      $$DeleteLogsTableTableManager(_db, _db.deleteLogs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}

mixin _$SubjectsDaoMixin on DatabaseAccessor<StudyDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $DocumentsTable get documents => attachedDatabase.documents;
  $DeleteLogsTable get deleteLogs => attachedDatabase.deleteLogs;
}
mixin _$DocTypesDaoMixin on DatabaseAccessor<StudyDatabase> {
  $DocTypesTable get docTypes => attachedDatabase.docTypes;
  $DeleteLogsTable get deleteLogs => attachedDatabase.deleteLogs;
}
mixin _$DocumentsDaoMixin on DatabaseAccessor<StudyDatabase> {
  $DocumentsTable get documents => attachedDatabase.documents;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $DocTypesTable get docTypes => attachedDatabase.docTypes;
  $DeleteLogsTable get deleteLogs => attachedDatabase.deleteLogs;
}
mixin _$StudyGoalsDaoMixin on DatabaseAccessor<StudyDatabase> {
  $StudyGoalsTable get studyGoals => attachedDatabase.studyGoals;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $DeleteLogsTable get deleteLogs => attachedDatabase.deleteLogs;
}
