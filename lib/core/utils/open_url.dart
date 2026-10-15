import 'package:url_launcher/url_launcher.dart';

import '../widgets/insta_ui.dart';
import 'package:flutter/widgets.dart';

/// 외부 브라우저로 링크를 연다. 열 수 없으면 토스트로 알린다.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
      .catchError((_) => false);
  if (!ok && context.mounted) {
    showInstaToast(context, '링크를 열 수 없습니다', isError: true);
  }
}
