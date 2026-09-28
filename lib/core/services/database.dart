import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

class AnalysisRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// 사용자가 고른 원본. 다시 변형할 때의 입력이므로 절대 변형본으로 덮지 않는다.
  TextColumn get imagePath => text()();

  /// 변형(after) 결과의 축소본. 홈·기록 목록이 보여 주는 그림이다.
  /// null이면 목록은 [imagePath]로 폴백한다 (v2 이전 기록).
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get analysisJson => text()();
  TextColumn get styleCategory => text()();
  TextColumn get colorTemperature => text()();

  /// 변형을 AI 없이 다시 그리는 데 필요한 값 (서버 params, autoEdits,
  /// regionParams, 톤 커브, 보정 설명). `StoredTransform`이 인코딩한다.
  /// null이면 v3 이전 기록 — 다시 열 때 분석을 한 번 더 돌려 채운다.
  TextColumn get transformJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [AnalysisRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 테스트용 — 인메모리 DB 등 임의의 실행기로 연다.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // overallScore 컬럼 제거. 기존 테이블에 NOT NULL로 남아 있으면
            // 새 스키마 기준으로 만들어진 INSERT가 실패한다. TableMigration이
            // 새 정의로 테이블을 다시 만들고 남는 컬럼 값을 옮겨 준다.
            // 새 정의에는 있지만 옛 테이블에 없는 컬럼(v3의 transformJson 등)은
            // 복사 대상에서 빼야 SELECT가 실패하지 않는다.
            final existing = await _existingColumns('analysis_records');
            await m.alterTable(TableMigration(
              analysisRecords,
              newColumns: [
                for (final c in analysisRecords.$columns)
                  if (!existing.contains(c.name)) c,
              ],
            ));
            return; // 위에서 최신 정의로 다시 만들었으므로 아래 단계는 필요 없다
          }
          if (from < 3) {
            await m.addColumn(analysisRecords, analysisRecords.transformJson);
          }
        },
      );

  Future<Set<String>> _existingColumns(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return {for (final r in rows) r.read<String>('name')};
  }

  Future<int> insertAnalysis(AnalysisRecordsCompanion entry) {
    return into(analysisRecords).insert(entry);
  }

  Future<List<AnalysisRecord>> getAllAnalyses() {
    return (select(analysisRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<AnalysisRecord>> watchAllAnalyses() {
    return (select(analysisRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<AnalysisRecord>> getRecentAnalyses({int limit = 5}) {
    return (select(analysisRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<AnalysisRecord>> watchByStyle(String style) {
    return (select(analysisRecords)
          ..where((t) => t.styleCategory.equals(style))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<int> deleteAnalysis(int id) {
    return (delete(analysisRecords)..where((t) => t.id.equals(id))).go();
  }

  Future<AnalysisRecord?> getAnalysisById(int id) {
    return (select(analysisRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 기존 기록의 변형 재현 정보만 바꾼다.
  Future<int> updateTransformJson(int id, String? transformJson) {
    return (update(analysisRecords)..where((t) => t.id.equals(id)))
        .write(AnalysisRecordsCompanion(transformJson: Value(transformJson)));
  }

  /// 기존 기록을 다시 분석한 결과로 갱신한다 (새 행을 만들지 않는다).
  ///
  /// [entry]에서 값이 있는 필드만 덮는다. imagePath·createdAt은 보통 비워 둔다.
  Future<int> updateAnalysisRecord(int id, AnalysisRecordsCompanion entry) {
    return (update(analysisRecords)..where((t) => t.id.equals(id)))
        .write(entry);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gamdo.db'));
    return NativeDatabase.createInBackground(file);
  });
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}
