import '../../domain/repositories/style_repository.dart';
import '../datasources/firebase_datasource.dart';

/// [StyleRepository] 구현체 — FirebaseDatasource에 위임.
class StyleRepositoryImpl implements StyleRepository {
  final FirebaseDatasource _datasource;

  StyleRepositoryImpl({required FirebaseDatasource datasource})
      : _datasource = datasource;

  @override
  Future<void> saveStyleProfile({
    required String userId,
    required Map<String, dynamic> styleProfile,
    String? summary,
    List<dynamic>? recommendations,
  }) =>
      _datasource.saveStyleProfile(
        userId: userId,
        styleProfile: styleProfile,
        summary: summary,
        recommendations: recommendations,
      );

  @override
  Future<Map<String, dynamic>?> getStyleProfile(String userId) =>
      _datasource.getStyleProfile(userId);

  @override
  Future<void> deleteStyleProfile(String userId) =>
      _datasource.deleteStyleProfile(userId);
}
