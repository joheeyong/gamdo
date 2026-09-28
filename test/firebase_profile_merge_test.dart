import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/services/firebase_service.dart';

void main() {
  group('mergeLearnedTargetParams', () {
    test('재분석 프로필에 기존 학습 targetParams를 이어 붙인다', () {
      final merged = mergeLearnedTargetParams(
        {'primaryStyle': 'new'},
        {
          'primaryStyle': 'old',
          'targetParams': {'warmth': 0.3},
        },
      );
      expect(merged['primaryStyle'], 'new');
      expect(merged['targetParams'], {'warmth': 0.3});
    });

    test('새 프로필에 targetParams가 있으면 새 값을 쓴다', () {
      final merged = mergeLearnedTargetParams(
        {
          'targetParams': {'warmth': 0.9},
        },
        {
          'targetParams': {'warmth': 0.3},
        },
      );
      expect(merged['targetParams'], {'warmth': 0.9});
    });

    test('이전 프로필이 없으면 그대로', () {
      final fresh = {'primaryStyle': 'a'};
      expect(mergeLearnedTargetParams(fresh, null), same(fresh));
    });
  });

  test('database.rules.json은 users/\$uid를 본인만 읽고 쓰게 한다', () {
    final rules = jsonDecode(File('database.rules.json').readAsStringSync())
        as Map<String, dynamic>;
    final uidRule = rules['rules']['users'][r'$uid'] as Map<String, dynamic>;
    expect(uidRule['.read'], r'auth != null && auth.uid === $uid');
    expect(uidRule['.write'], r'auth != null && auth.uid === $uid');

    final firebaseJson = jsonDecode(File('firebase.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(firebaseJson['database'], {'rules': 'database.rules.json'});
    expect(firebaseJson['flutter'], isNotNull);
  });
}
