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
  /// `users/$userId`를 통째로 set()하면 같은 노드 아래의 `feedback/`
  /// 히스토리까지 지워진다. 프로필 필드만 update()로 덮어쓴다.
  /// styleProfile도 필드 단위로 써서 학습된 targetParams를 보존한다.
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

  /// 사용자 피드백(슬라이더 delta)을 RTDB에 저장.
  Future<void> saveFeedback({
    required String userId,
    required Map<String, double> delta,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _db.child('users/$userId/feedback/$timestamp').set(delta);
      developer.log('Feedback saved for user $userId', name: 'FirebaseService');
    } catch (e) {
      developer.log('Failed to save feedback: $e', name: 'FirebaseService');
    }
  }

  /// 사용자의 누적 피드백 히스토리를 로드.
  Future<List<Map<String, double>>> loadFeedbackHistory(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId/feedback').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final history = <Map<String, double>>[];

      for (final entry in data.values) {
        if (entry is Map) {
          final delta = <String, double>{};
          for (final e in Map<String, dynamic>.from(entry).entries) {
            delta[e.key] = (e.value as num).toDouble();
          }
          history.add(delta);
        }
      }

      developer.log(
          'Loaded ${history.length} feedback entries for user $userId',
          name: 'FirebaseService');
      return history;
    } catch (e) {
      developer.log('Failed to load feedback history: $e',
          name: 'FirebaseService');
      return [];
    }
  }

  /// 누적 피드백 평균으로 targetParams를 업데이트.
  /// new_target[key] = old_target[key] + learningRate * avg_delta[key]
  Future<void> updateTargetParams({
    required String userId,
    required Map<String, double> avgDelta,
    double learningRate = 0.3,
  }) async {
    try {
      // 기존 targetParams 읽기
      final snapshot =
          await _db.child('users/$userId/styleProfile/targetParams').get();
      final oldParams = <String, double>{};
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final e in data.entries) {
          oldParams[e.key] = (e.value as num).toDouble();
        }
      }

      // 새 targetParams 계산
      final newParams = <String, double>{};
      final allKeys = {...oldParams.keys, ...avgDelta.keys};
      for (final key in allKeys) {
        final oldVal = oldParams[key] ?? 0.0;
        final deltaVal = avgDelta[key] ?? 0.0;
        newParams[key] = (oldVal + learningRate * deltaVal).clamp(-1.0, 1.0);
      }

      await _db
          .child('users/$userId/styleProfile/targetParams')
          .set(newParams);
      developer.log('targetParams updated for user $userId: $newParams',
          name: 'FirebaseService');
    } catch (e) {
      developer.log('Failed to update targetParams: $e',
          name: 'FirebaseService');
    }
  }
}

/// [FirebaseService.saveStyleProfile]이 `users/$userId`에 update()할 맵.
///
/// styleProfile은 통째로 덮지 않고 `styleProfile/<필드>` 다중 경로로 쓴다.
/// 슬라이더 피드백으로 학습된 `styleProfile/targetParams`는 재분석 결과에
/// 없으므로 그대로 남는다(넘어온 프로필에 targetParams가 있으면 그 값으로 쓴다).
///
/// summary/recommendations는 자동 분석 결과에 딸린 값이다. 프로필을 수동
/// 편집해 저장할 때(null로 넘어옴) 옛 분석의 요약이 남지 않도록 null을 써서
/// 지운다 — 예전 set() 동작과 같다. `feedback/` 등 나머지 자식은 건드리지 않는다.
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

/// 재분석으로 받은 새 프로필에 기존(인메모리) 프로필의 학습된 targetParams를
/// 이어 붙인다. 새 프로필에 targetParams가 있으면 새 값을 쓴다.
Map<String, dynamic> mergeLearnedTargetParams(
  Map<String, dynamic> fresh,
  Map<String, dynamic>? previous,
) {
  final learned = previous?['targetParams'];
  if (learned == null || fresh['targetParams'] != null) return fresh;
  return {...fresh, 'targetParams': learned};
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
