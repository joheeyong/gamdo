// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AnalysisRecordsTable extends AnalysisRecords
    with TableInfo<$AnalysisRecordsTable, AnalysisRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysisRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _analysisJsonMeta = const VerificationMeta(
    'analysisJson',
  );
  @override
  late final GeneratedColumn<String> analysisJson = GeneratedColumn<String>(
    'analysis_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overallScoreMeta = const VerificationMeta(
    'overallScore',
  );
  @override
  late final GeneratedColumn<int> overallScore = GeneratedColumn<int>(
    'overall_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _styleCategoryMeta = const VerificationMeta(
    'styleCategory',
  );
  @override
  late final GeneratedColumn<String> styleCategory = GeneratedColumn<String>(
    'style_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorTemperatureMeta = const VerificationMeta(
    'colorTemperature',
  );
  @override
  late final GeneratedColumn<String> colorTemperature = GeneratedColumn<String>(
    'color_temperature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imagePath,
    thumbnailPath,
    analysisJson,
    overallScore,
    styleCategory,
    colorTemperature,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnalysisRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('analysis_json')) {
      context.handle(
        _analysisJsonMeta,
        analysisJson.isAcceptableOrUnknown(
          data['analysis_json']!,
          _analysisJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_analysisJsonMeta);
    }
    if (data.containsKey('overall_score')) {
      context.handle(
        _overallScoreMeta,
        overallScore.isAcceptableOrUnknown(
          data['overall_score']!,
          _overallScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overallScoreMeta);
    }
    if (data.containsKey('style_category')) {
      context.handle(
        _styleCategoryMeta,
        styleCategory.isAcceptableOrUnknown(
          data['style_category']!,
          _styleCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_styleCategoryMeta);
    }
    if (data.containsKey('color_temperature')) {
      context.handle(
        _colorTemperatureMeta,
        colorTemperature.isAcceptableOrUnknown(
          data['color_temperature']!,
          _colorTemperatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_colorTemperatureMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalysisRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      analysisJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analysis_json'],
      )!,
      overallScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_score'],
      )!,
      styleCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style_category'],
      )!,
      colorTemperature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_temperature'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnalysisRecordsTable createAlias(String alias) {
    return $AnalysisRecordsTable(attachedDatabase, alias);
  }
}

class AnalysisRecord extends DataClass implements Insertable<AnalysisRecord> {
  final int id;
  final String imagePath;
  final String? thumbnailPath;
  final String analysisJson;
  final int overallScore;
  final String styleCategory;
  final String colorTemperature;
  final DateTime createdAt;
  const AnalysisRecord({
    required this.id,
    required this.imagePath,
    this.thumbnailPath,
    required this.analysisJson,
    required this.overallScore,
    required this.styleCategory,
    required this.colorTemperature,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['image_path'] = Variable<String>(imagePath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['analysis_json'] = Variable<String>(analysisJson);
    map['overall_score'] = Variable<int>(overallScore);
    map['style_category'] = Variable<String>(styleCategory);
    map['color_temperature'] = Variable<String>(colorTemperature);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnalysisRecordsCompanion toCompanion(bool nullToAbsent) {
    return AnalysisRecordsCompanion(
      id: Value(id),
      imagePath: Value(imagePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      analysisJson: Value(analysisJson),
      overallScore: Value(overallScore),
      styleCategory: Value(styleCategory),
      colorTemperature: Value(colorTemperature),
      createdAt: Value(createdAt),
    );
  }

  factory AnalysisRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisRecord(
      id: serializer.fromJson<int>(json['id']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      analysisJson: serializer.fromJson<String>(json['analysisJson']),
      overallScore: serializer.fromJson<int>(json['overallScore']),
      styleCategory: serializer.fromJson<String>(json['styleCategory']),
      colorTemperature: serializer.fromJson<String>(json['colorTemperature']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'imagePath': serializer.toJson<String>(imagePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'analysisJson': serializer.toJson<String>(analysisJson),
      'overallScore': serializer.toJson<int>(overallScore),
      'styleCategory': serializer.toJson<String>(styleCategory),
      'colorTemperature': serializer.toJson<String>(colorTemperature),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnalysisRecord copyWith({
    int? id,
    String? imagePath,
    Value<String?> thumbnailPath = const Value.absent(),
    String? analysisJson,
    int? overallScore,
    String? styleCategory,
    String? colorTemperature,
    DateTime? createdAt,
  }) => AnalysisRecord(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    analysisJson: analysisJson ?? this.analysisJson,
    overallScore: overallScore ?? this.overallScore,
    styleCategory: styleCategory ?? this.styleCategory,
    colorTemperature: colorTemperature ?? this.colorTemperature,
    createdAt: createdAt ?? this.createdAt,
  );
  AnalysisRecord copyWithCompanion(AnalysisRecordsCompanion data) {
    return AnalysisRecord(
      id: data.id.present ? data.id.value : this.id,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      analysisJson: data.analysisJson.present
          ? data.analysisJson.value
          : this.analysisJson,
      overallScore: data.overallScore.present
          ? data.overallScore.value
          : this.overallScore,
      styleCategory: data.styleCategory.present
          ? data.styleCategory.value
          : this.styleCategory,
      colorTemperature: data.colorTemperature.present
          ? data.colorTemperature.value
          : this.colorTemperature,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisRecord(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('analysisJson: $analysisJson, ')
          ..write('overallScore: $overallScore, ')
          ..write('styleCategory: $styleCategory, ')
          ..write('colorTemperature: $colorTemperature, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    imagePath,
    thumbnailPath,
    analysisJson,
    overallScore,
    styleCategory,
    colorTemperature,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisRecord &&
          other.id == this.id &&
          other.imagePath == this.imagePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.analysisJson == this.analysisJson &&
          other.overallScore == this.overallScore &&
          other.styleCategory == this.styleCategory &&
          other.colorTemperature == this.colorTemperature &&
          other.createdAt == this.createdAt);
}

class AnalysisRecordsCompanion extends UpdateCompanion<AnalysisRecord> {
  final Value<int> id;
  final Value<String> imagePath;
  final Value<String?> thumbnailPath;
  final Value<String> analysisJson;
  final Value<int> overallScore;
  final Value<String> styleCategory;
  final Value<String> colorTemperature;
  final Value<DateTime> createdAt;
  const AnalysisRecordsCompanion({
    this.id = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.analysisJson = const Value.absent(),
    this.overallScore = const Value.absent(),
    this.styleCategory = const Value.absent(),
    this.colorTemperature = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnalysisRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String imagePath,
    this.thumbnailPath = const Value.absent(),
    required String analysisJson,
    required int overallScore,
    required String styleCategory,
    required String colorTemperature,
    this.createdAt = const Value.absent(),
  }) : imagePath = Value(imagePath),
       analysisJson = Value(analysisJson),
       overallScore = Value(overallScore),
       styleCategory = Value(styleCategory),
       colorTemperature = Value(colorTemperature);
  static Insertable<AnalysisRecord> custom({
    Expression<int>? id,
    Expression<String>? imagePath,
    Expression<String>? thumbnailPath,
    Expression<String>? analysisJson,
    Expression<int>? overallScore,
    Expression<String>? styleCategory,
    Expression<String>? colorTemperature,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imagePath != null) 'image_path': imagePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (analysisJson != null) 'analysis_json': analysisJson,
      if (overallScore != null) 'overall_score': overallScore,
      if (styleCategory != null) 'style_category': styleCategory,
      if (colorTemperature != null) 'color_temperature': colorTemperature,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnalysisRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? imagePath,
    Value<String?>? thumbnailPath,
    Value<String>? analysisJson,
    Value<int>? overallScore,
    Value<String>? styleCategory,
    Value<String>? colorTemperature,
    Value<DateTime>? createdAt,
  }) {
    return AnalysisRecordsCompanion(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      analysisJson: analysisJson ?? this.analysisJson,
      overallScore: overallScore ?? this.overallScore,
      styleCategory: styleCategory ?? this.styleCategory,
      colorTemperature: colorTemperature ?? this.colorTemperature,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (analysisJson.present) {
      map['analysis_json'] = Variable<String>(analysisJson.value);
    }
    if (overallScore.present) {
      map['overall_score'] = Variable<int>(overallScore.value);
    }
    if (styleCategory.present) {
      map['style_category'] = Variable<String>(styleCategory.value);
    }
    if (colorTemperature.present) {
      map['color_temperature'] = Variable<String>(colorTemperature.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisRecordsCompanion(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('analysisJson: $analysisJson, ')
          ..write('overallScore: $overallScore, ')
          ..write('styleCategory: $styleCategory, ')
          ..write('colorTemperature: $colorTemperature, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnalysisRecordsTable analysisRecords = $AnalysisRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [analysisRecords];
}

typedef $$AnalysisRecordsTableCreateCompanionBuilder =
    AnalysisRecordsCompanion Function({
      Value<int> id,
      required String imagePath,
      Value<String?> thumbnailPath,
      required String analysisJson,
      required int overallScore,
      required String styleCategory,
      required String colorTemperature,
      Value<DateTime> createdAt,
    });
typedef $$AnalysisRecordsTableUpdateCompanionBuilder =
    AnalysisRecordsCompanion Function({
      Value<int> id,
      Value<String> imagePath,
      Value<String?> thumbnailPath,
      Value<String> analysisJson,
      Value<int> overallScore,
      Value<String> styleCategory,
      Value<String> colorTemperature,
      Value<DateTime> createdAt,
    });

class $$AnalysisRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AnalysisRecordsTable> {
  $$AnalysisRecordsTableFilterComposer({
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

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analysisJson => $composableBuilder(
    column: $table.analysisJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get styleCategory => $composableBuilder(
    column: $table.styleCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorTemperature => $composableBuilder(
    column: $table.colorTemperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnalysisRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalysisRecordsTable> {
  $$AnalysisRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analysisJson => $composableBuilder(
    column: $table.analysisJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get styleCategory => $composableBuilder(
    column: $table.styleCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorTemperature => $composableBuilder(
    column: $table.colorTemperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalysisRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalysisRecordsTable> {
  $$AnalysisRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get analysisJson => $composableBuilder(
    column: $table.analysisJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get styleCategory => $composableBuilder(
    column: $table.styleCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorTemperature => $composableBuilder(
    column: $table.colorTemperature,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnalysisRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnalysisRecordsTable,
          AnalysisRecord,
          $$AnalysisRecordsTableFilterComposer,
          $$AnalysisRecordsTableOrderingComposer,
          $$AnalysisRecordsTableAnnotationComposer,
          $$AnalysisRecordsTableCreateCompanionBuilder,
          $$AnalysisRecordsTableUpdateCompanionBuilder,
          (
            AnalysisRecord,
            BaseReferences<
              _$AppDatabase,
              $AnalysisRecordsTable,
              AnalysisRecord
            >,
          ),
          AnalysisRecord,
          PrefetchHooks Function()
        > {
  $$AnalysisRecordsTableTableManager(
    _$AppDatabase db,
    $AnalysisRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysisRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysisRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalysisRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String> analysisJson = const Value.absent(),
                Value<int> overallScore = const Value.absent(),
                Value<String> styleCategory = const Value.absent(),
                Value<String> colorTemperature = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnalysisRecordsCompanion(
                id: id,
                imagePath: imagePath,
                thumbnailPath: thumbnailPath,
                analysisJson: analysisJson,
                overallScore: overallScore,
                styleCategory: styleCategory,
                colorTemperature: colorTemperature,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String imagePath,
                Value<String?> thumbnailPath = const Value.absent(),
                required String analysisJson,
                required int overallScore,
                required String styleCategory,
                required String colorTemperature,
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnalysisRecordsCompanion.insert(
                id: id,
                imagePath: imagePath,
                thumbnailPath: thumbnailPath,
                analysisJson: analysisJson,
                overallScore: overallScore,
                styleCategory: styleCategory,
                colorTemperature: colorTemperature,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnalysisRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnalysisRecordsTable,
      AnalysisRecord,
      $$AnalysisRecordsTableFilterComposer,
      $$AnalysisRecordsTableOrderingComposer,
      $$AnalysisRecordsTableAnnotationComposer,
      $$AnalysisRecordsTableCreateCompanionBuilder,
      $$AnalysisRecordsTableUpdateCompanionBuilder,
      (
        AnalysisRecord,
        BaseReferences<_$AppDatabase, $AnalysisRecordsTable, AnalysisRecord>,
      ),
      AnalysisRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnalysisRecordsTableTableManager get analysisRecords =>
      $$AnalysisRecordsTableTableManager(_db, _db.analysisRecords);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'63ee888947c6b70ff7ffbf17b8b09651fda53b06';
