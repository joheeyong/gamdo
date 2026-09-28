import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// DB에 남기는 이미지 경로 ↔ 실제 파일 경로 변환.
///
/// iOS는 앱을 업데이트(재설치)할 때마다 컨테이너 경로
/// (`.../Application/<UUID>/Documents`)가 바뀐다. 절대 경로를 DB에 두면
/// 업데이트 뒤 기록 화면의 사진이 전부 사라진다. 그래서 새 기록은
/// 문서 디렉터리 기준 상대 경로로 저장하고, 읽을 때 현재 문서 디렉터리에
/// 붙인다. 예전에 저장된 절대 경로도 읽을 때 `Documents/` 뒤 부분을
/// 현재 문서 디렉터리로 옮겨 붙여 살린다 (DB 마이그레이션 없음).

/// 문서 디렉터리 경로를 돌려주는 함수. 테스트에서 바꿔 끼운다.
typedef DocumentsDirResolver = Future<String> Function();

Future<String> defaultDocumentsDir() async =>
    (await getApplicationDocumentsDirectory()).path;

/// [absolutePath]가 [docsDir] 안이면 상대 경로로, 아니면 그대로 돌려준다.
String toStoredPath(String absolutePath, String docsDir) {
  if (p.isWithin(docsDir, absolutePath)) {
    return p.relative(absolutePath, from: docsDir);
  }
  return absolutePath;
}

/// DB에 저장된 경로를 지금 열 수 있는 절대 경로로 바꾼다.
///
/// - 상대 경로: [docsDir]에 붙인다.
/// - 절대 경로이고 [docsDir] 안이거나 파일이 있으면: 그대로.
/// - 절대 경로인데 파일이 없고 `Documents/`를 포함하면: 그 뒤 부분을
///   [docsDir]에 붙인다 (iOS 컨테이너 경로 변경 대응).
String resolveStoredPath(
  String stored,
  String docsDir, {
  bool Function(String path)? exists,
}) {
  if (stored.isEmpty) return stored;
  if (p.isRelative(stored)) return p.join(docsDir, stored);
  if (p.isWithin(docsDir, stored)) return stored;

  final fileExists = exists ?? (path) => File(path).existsSync();
  if (fileExists(stored)) return stored;

  const marker = '/Documents/';
  final idx = stored.lastIndexOf(marker);
  if (idx < 0) return stored;
  final tail = stored.substring(idx + marker.length);
  if (tail.isEmpty) return stored;
  return p.join(docsDir, tail);
}

/// 레코드의 imagePath/thumbnailPath를 읽기용 절대 경로로 바꾼 사본.
AnalysisRecord resolveRecordPaths(
  AnalysisRecord record,
  String docsDir, {
  bool Function(String path)? exists,
}) {
  final thumb = record.thumbnailPath;
  return record.copyWith(
    imagePath: resolveStoredPath(record.imagePath, docsDir, exists: exists),
    thumbnailPath: Value(
      thumb == null ? null : resolveStoredPath(thumb, docsDir, exists: exists),
    ),
  );
}

/// DB 스트림의 레코드 경로를 읽기용으로 바꾼다. 문서 디렉터리는 한 번만 구한다.
Stream<List<AnalysisRecord>> resolveRecordStream(
  Stream<List<AnalysisRecord>> source,
  DocumentsDirResolver documentsDir,
) {
  Future<String>? docs;
  return source.asyncMap((records) async {
    final dir = await (docs ??= documentsDir());
    return [for (final r in records) resolveRecordPaths(r, dir)];
  });
}
