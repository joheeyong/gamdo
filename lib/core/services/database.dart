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

  // Insert
  Future<int> insertAnalysis(AnalysisRecordsCompanion entry) {
    return into(analysisRecords).insert(entry);
  }

  // Get all, ordered by date
  Future<List<AnalysisRecord>> getAllAnalyses() {
    return (select(analysisRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // Watch all analyses as stream
  Stream<List<AnalysisRecord>> watchAllAnalyses() {
    return (select(analysisRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // Get recent analyses (limit)
  Future<List<AnalysisRecord>> getRecentAnalyses({int limit = 5}) {
    return (select(analysisRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  // Filter by style
  Stream<List<AnalysisRecord>> watchByStyle(String style) {
    return (select(analysisRecords)
          ..where((t) => t.styleCategory.equals(style))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // Delete
  Future<int> deleteAnalysis(int id) {
    return (delete(analysisRecords)..where((t) => t.id.equals(id))).go();
  }

  // Get by id
  Future<AnalysisRecord?> getAnalysisById(int id) {
    return (select(analysisRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
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
