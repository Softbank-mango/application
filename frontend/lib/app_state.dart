import 'package:flutter/material.dart';

/// 앱의 글로벌 UI 상태(테마, 로케일)를 관리합니다.
///
/// 이 앱은 상태가 단순하므로, Provider/Riverpod 대신
/// 싱글톤 ValueNotifier를 사용하여 상태를 전역적으로 공유합니다.
class AppState {
  // 싱글톤 인스턴스
  static final AppState instance = AppState._internal();
  factory AppState() => instance;
  AppState._internal();

  /// 현재 테마 모드(system, light, dark)
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  /// 현재 언어(locale)
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ko')); // 기본값 한국어
}