import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 공유 시도 결과.
enum InstagramShareResult {
  /// 인스타그램이 열렸다. 실제 게시는 사용자가 인스타그램 안에서 마무리한다.
  opened,

  /// 인스타그램이 설치되어 있지 않다.
  notInstalled,

  /// 인스타그램은 있지만 여는 데 실패했다 (권한, 앱 버전, 딥링크 거부 등).
  failed,
}

/// 변형된 사진을 인스타그램 스토리·피드 편집 화면으로 바로 넘긴다.
///
/// OS 공유 시트를 띄우지 않고 인스타그램으로 직행한다.
/// 스토리는 Meta가 문서로 지원하는 방식(iOS `instagram-stories://share`,
/// Android `com.instagram.share.ADD_TO_STORY`)이라 비교적 안정적이고,
/// 피드는 플랫폼별로 경로가 다르다 (iOS는 사진 앨범의 로컬 식별자,
/// Android는 인스타그램 패키지를 지정한 전송 인텐트).
///
/// 어느 쪽이든 마지막 [공유] 버튼은 사용자가 인스타그램 안에서 누른다.
/// 프로그램이 게시까지 끝내려면 Content Publishing API가 필요하고,
/// 그건 비즈니스 계정과 Meta 앱 심사를 전제로 한다.
class InstagramShareService {
  static const MethodChannel _channel =
      MethodChannel('gamdo/instagram_share');

  /// 스토리 공유 시 인스타그램에 알리는 출처 앱 ID.
  ///
  /// Meta 문서상 페이스북 앱 ID여야 한다. 값이 맞지 않으면 인스타그램이
  /// 스토리 편집 화면을 열지 않을 수 있다.
  static const String sourceApplicationId = '897959926379711';

  /// 인스타그램 설치 여부.
  Future<bool> isInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isInstalled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 스토리 편집 화면으로 사진을 넘긴다.
  Future<InstagramShareResult> shareToStory(Uint8List imageBytes) =>
      _share('shareToStory', imageBytes);

  /// 피드 편집 화면으로 사진을 넘긴다.
  ///
  /// iOS에서는 사진 앨범에 먼저 저장한 뒤 그 사진을 열기 때문에,
  /// 앨범에 한 장이 남는다 (인스타그램이 앨범의 사진만 참조할 수 있다).
  Future<InstagramShareResult> shareToFeed(Uint8List imageBytes) =>
      _share('shareToFeed', imageBytes);

  Future<InstagramShareResult> _share(
    String method,
    Uint8List imageBytes,
  ) async {
    File? file;
    try {
      file = await _writeTempImage(imageBytes);
      final code = await _channel.invokeMethod<String>(method, {
        'path': file.path,
        'sourceApplicationId': sourceApplicationId,
      });
      return switch (code) {
        'opened' => InstagramShareResult.opened,
        'notInstalled' => InstagramShareResult.notInstalled,
        _ => InstagramShareResult.failed,
      };
    } on PlatformException {
      return InstagramShareResult.failed;
    } on MissingPluginException {
      // 채널이 없는 플랫폼(데스크톱·웹)
      return InstagramShareResult.notInstalled;
    } finally {
      // 네이티브가 이미 읽어 간 뒤라 지워도 안전하다.
      // 다만 Android는 인텐트가 URI를 지연 로딩할 수 있어 남겨 둔다.
      if (file != null && Platform.isIOS) {
        try {
          await file.delete();
        } on FileSystemException {
          // 정리 실패는 무시 — 임시 디렉터리는 OS가 회수한다
        }
      }
    }
  }

  Future<File> _writeTempImage(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'ig_share_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return File(path).writeAsBytes(bytes, flush: true);
  }
}
