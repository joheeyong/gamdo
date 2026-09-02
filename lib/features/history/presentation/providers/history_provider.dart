import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/services/database.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';

/// 정렬 옵션.
enum HistorySortOrder { newest, scoreHigh, scoreLow }

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(database: ref.watch(appDatabaseProvider));
});

final selectedStyleFilterProvider =
    StateProvider<String?>((ref) => null);

final selectedSortOrderProvider =
    StateProvider<HistorySortOrder>((ref) => HistorySortOrder.newest);

final filteredAnalysesProvider = StreamProvider<List<AnalysisRecord>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  final filter = ref.watch(selectedStyleFilterProvider);
  final sortOrder = ref.watch(selectedSortOrderProvider);

  switch (sortOrder) {
    case HistorySortOrder.newest:
      if (filter != null && filter.isNotEmpty) {
        return repo.watchByStyle(filter);
      }
      return repo.watchAll();
    case HistorySortOrder.scoreHigh:
      if (filter != null && filter.isNotEmpty) {
        return repo.watchByStyleSortedByScore(filter, ascending: false);
      }
      return repo.watchAllSortedByScore(ascending: false);
    case HistorySortOrder.scoreLow:
      if (filter != null && filter.isNotEmpty) {
        return repo.watchByStyleSortedByScore(filter, ascending: true);
      }
      return repo.watchAllSortedByScore(ascending: true);
  }
});
