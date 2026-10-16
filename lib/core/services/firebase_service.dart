import 'dart:developer' as developer;

import 'package:firebase_database/firebase_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_service.g.dart';

@riverpod
FirebaseService firebaseService(Ref ref) => FirebaseService();

class FirebaseService {
  static final FirebaseDatabase _instance = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://gamdo-app-2026-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
  final DatabaseReference _db = _instance.ref();

  /// RTDB에 스타일 프로필 저장.
  ///
  /// `users/$userId`를 통째로 set()하지 않고 프로필 필드만 update()로
  /// 덮어쓴다 — 같은 노드 아래의 다른 자식을 지우지 않기 위해서다.
  Future<void> saveStyleProfile({
    required String userId,
    required Map<String, dynamic> styleProfile,
    String? summary,
    List<dynamic>? recommendations,
  }) async {
    try {
      await _db
          .child('users/$userId')
          .update(buildStyleProfileUpdate(
            styleProfile: styleProfile,
            summary: summary,
            recommendations: recommendations,
          ));
      developer.log('Style profile saved for user $userId',
          name: 'FirebaseService');
    } catch (e) {
      developer.log('Failed to save style profile: $e',
          name: 'FirebaseService');
      rethrow;
    }
  }

  /// RTDB에서 스타일 프로필 읽기.
  Future<Map<String, dynamic>?> getStyleProfile(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId').get();
      if (!snapshot.exists || snapshot.value == null) return null;

      // RTDB는 중첩 Map을 Map<Object?, Object?>로 반환하므로 재귀 변환 필요.
      final data = _deepCast(snapshot.value) as Map<String, dynamic>;
      developer.log('Style profile loaded for user $userId',
          name: 'FirebaseService');
      return data;
    } catch (e) {
      developer.log('Failed to load style profile: $e',
          name: 'FirebaseService');
      return null;
    }
  }

  /// RTDB에서 스타일 프로필 삭제.
  Future<void> deleteStyleProfile(String userId) async {
    try {
      await _db.child('users/$userId').remove();
      developer.log('Style profile deleted for user $userId',
          name: 'FirebaseService');
    } catch (e) {
      developer.log('Failed to delete style profile: $e',
          name: 'FirebaseService');
      rethrow;
    }
  }
}

/// [FirebaseService.saveStyleProfile]이 `users/$userId`에 update()할 맵.
///
/// styleProfile은 통째로 덮지 않고 `styleProfile/<필드>` 다중 경로로 쓴다
/// (넘어온 프로필에 없는 필드는 건드리지 않는다).
///
/// summary/recommendations는 자동 분석 결과에 딸린 값이다. 프로필을 수동
/// 편집해 저장할 때(null로 넘어옴) 옛 분석의 요약이 남지 않도록 null을 써서
/// 지운다 — 예전 set() 동작과 같다. 그 밖의 자식 노드는 건드리지 않는다.
Map<String, Object?> buildStyleProfileUpdate({
  required Map<String, dynamic> styleProfile,
  String? summary,
  List<dynamic>? recommendations,
  DateTime? now,
}) {
  return {
    for (final entry in styleProfile.entries)
      'styleProfile/${entry.key}': entry.value,
    'analyzedAt': (now ?? DateTime.now()).toIso8601String(),
    'summary': summary,
    'recommendations': recommendations,
  };
}

/// RTDB가 돌려주는 `Map<Object?, Object?>`/`List<Object?>` 트리를
/// `Map<String, dynamic>`/`List<dynamic>`로 재귀 변환한다.
dynamic _deepCast(Object? value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _deepCast(entry.value),
    };
  }
  if (value is List) {
    return value.map(_deepCast).toList();
  }
  return value;
}
