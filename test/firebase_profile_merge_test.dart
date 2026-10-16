import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
