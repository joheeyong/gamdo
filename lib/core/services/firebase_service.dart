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
  Future<void> saveStyleProfile({
    required String userId,
    required Map<String, dynamic> styleProfile,
    String? summary,
    List<dynamic>? recommendations,
  }) async {
    try {
      await _db.child('users/$userId').set({
        'styleProfile': styleProfile,
        'analyzedAt': DateTime.now().toIso8601String(),
        if (summary != null) 'summary': summary,
        if (recommendations != null) 'recommendations': recommendations,
      });
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

      final data = Map<String, dynamic>.from(snapshot.value as Map);
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
