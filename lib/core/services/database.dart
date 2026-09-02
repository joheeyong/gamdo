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
  TextColumn get imagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get analysisJson => text()();
  IntColumn get overallScore => integer()();
  TextColumn get styleCategory => text()();
  TextColumn get colorTemperature => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [AnalysisRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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

  /// 점수순 정렬 스트림.
  Stream<List<AnalysisRecord>> watchAllAnalysesByScore({bool ascending = false}) {
    return (select(analysisRecords)
          ..orderBy([(t) => ascending
              ? OrderingTerm.asc(t.overallScore)
              : OrderingTerm.desc(t.overallScore)]))
        .watch();
  }

  /// 스타일 필터 + 점수순 정렬 스트림.
  Stream<List<AnalysisRecord>> watchByStyleSortedByScore(
    String style, {
    bool ascending = false,
  }) {
    return (select(analysisRecords)
          ..where((t) => t.styleCategory.equals(style))
          ..orderBy([(t) => ascending
              ? OrderingTerm.asc(t.overallScore)
              : OrderingTerm.desc(t.overallScore)]))
        .watch();
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
