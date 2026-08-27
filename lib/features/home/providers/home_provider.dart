import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database.dart';

final recentAnalysesProvider = StreamProvider<List<AnalysisRecord>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllAnalyses();
});
