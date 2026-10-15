import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/services/instagram_service.dart';

void main() {
  test('state는 요청마다 다른 32자리 16진수', () {
    final a = InstagramService.newState();
    final b = InstagramService.newState();
    expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(a, isNot(b));
  });

  test('보낸 state와 같으면 인증 코드를 받는다', () {
    final s = InstagramService.newState(Random(1));
    final code = InstagramService.codeFromCallback(
        'gamdo://oauth/instagram?code=AQ123&state=$s#_', s);
    expect(code, 'AQ123');
  });

  test('state가 다르면 거부한다 (로그인 위조 방지)', () {
    expect(
      () => InstagramService.codeFromCallback(
          'gamdo://oauth/instagram?code=AQ123&state=attacker', 'mine'),
      throwsException,
    );
  });

  test('state가 없으면 거부한다', () {
    expect(
      () => InstagramService.codeFromCallback('gamdo://oauth/instagram?code=AQ123', 'mine'),
      throwsException,
    );
  });

  test('코드가 없으면 거부한다', () {
    expect(
      () => InstagramService.codeFromCallback('gamdo://oauth/instagram?state=mine', 'mine'),
      throwsException,
    );
  });
}
