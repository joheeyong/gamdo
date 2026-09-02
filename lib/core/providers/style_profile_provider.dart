import 'package:flutter_riverpod/legacy.dart';

/// 사용자 스타일 프로필을 저장하는 프로바이더 (교차 feature 공유 상태)
final userStyleProfileProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
