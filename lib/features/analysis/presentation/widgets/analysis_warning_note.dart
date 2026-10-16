import 'package:flutter/material.dart';

import '../../../../core/widgets/insta_ui.dart';

/// 서버가 분석의 일부를 채우지 못했을 때(`warnings`) 보여 주는 작은 안내.
///
/// 빈 카드나 '분석 불가'를 말없이 보여 주는 대신, 일부 정보가 빠졌다는
/// 사실만 조용히 알린다. 사진 보정 결과에는 영향이 없다.
class AnalysisWarningNote extends StatelessWidget {
  const AnalysisWarningNote({super.key});

  static const text = '일부 분석 정보를 불러오지 못했어요';

  @override
  Widget build(BuildContext context) {
    final color = context.instaSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}
