import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/services/database.dart';

final selectedStyleFilterProvider =
    StateProvider<String?>((ref) => null);

final filteredAnalysesProvider = StreamProvider<List<AnalysisRecord>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final filter = ref.watch(selectedStyleFilterProvider);

  if (filter != null && filter.isNotEmpty) {
    return db.watchByStyle(filter);
  }
  return db.watchAllAnalyses();
});
