import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/services/database.dart';
import 'package:gamdo/core/services/stored_path.dart';

void main() {
  const oldDocs =
      '/var/mobile/Containers/Data/Application/OLD-UUID/Documents';
  const newDocs =
      '/var/mobile/Containers/Data/Application/NEW-UUID/Documents';

  bool none(String _) => false;

  group('toStoredPath', () {
    test('문서 디렉터리 안의 경로는 상대 경로로 저장한다', () {
      expect(toStoredPath('$newDocs/photos/1.jpg', newDocs), 'photos/1.jpg');
    });
    test('문서 디렉터리 밖이면 그대로 둔다', () {
      expect(toStoredPath('/tmp/1.jpg', newDocs), '/tmp/1.jpg');
    });
  });

  group('resolveStoredPath', () {
    test('상대 경로는 현재 문서 디렉터리에 붙인다', () {
      expect(resolveStoredPath('photos/1.jpg', newDocs, exists: none),
          '$newDocs/photos/1.jpg');
    });
    test('현재 문서 디렉터리 안의 절대 경로는 그대로', () {
      expect(resolveStoredPath('$newDocs/photos/1.jpg', newDocs, exists: none),
          '$newDocs/photos/1.jpg');
    });
    test('iOS 업데이트로 컨테이너가 바뀐 옛 절대 경로를 새 경로로 옮긴다', () {
      expect(resolveStoredPath('$oldDocs/photos/1.jpg', newDocs, exists: none),
          '$newDocs/photos/1.jpg');
    });
    test('옛 경로에 파일이 실제로 있으면 그대로 쓴다', () {
      expect(
          resolveStoredPath('$oldDocs/photos/1.jpg', newDocs,
              exists: (_) => true),
          '$oldDocs/photos/1.jpg');
    });
    test('Documents가 없는 절대 경로(안드로이드 등)는 그대로', () {
      const android = '/data/user/0/com.x/app_flutter/photos/1.jpg';
      expect(resolveStoredPath(android, '/data/user/0/com.x/other',
              exists: none),
          android);
    });
  });

  test('resolveRecordPaths는 원본과 썸네일 경로를 모두 바꾸고 null은 유지한다', () {
    final record = AnalysisRecord(
      id: 1,
      imagePath: '$oldDocs/photos/1.jpg',
      thumbnailPath: 'photos/after_1.jpg',
      analysisJson: '{}',
      styleCategory: 's',
      colorTemperature: 'neutral',
      createdAt: DateTime(2026),
    );
    final resolved = resolveRecordPaths(record, newDocs, exists: none);
    expect(resolved.imagePath, '$newDocs/photos/1.jpg');
    expect(resolved.thumbnailPath, '$newDocs/photos/after_1.jpg');

    final noThumb = resolveRecordPaths(
        record.copyWith(thumbnailPath: const Value(null)), newDocs,
        exists: none);
    expect(noThumb.thumbnailPath, isNull);
  });
}
