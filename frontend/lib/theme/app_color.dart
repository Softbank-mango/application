import 'package:flutter/material.dart';

/// SoftBank Minimal UI Color System + Natural Accent Colors
/// - Light & Dark Mode 지원
/// - Orange / Green 계열은 눈의 피로를 줄이는 부드러운 색상 사용
class AppColors {
  /// 🎨 Light Mode Colors
  static const light = _AppPalette(
    primary: Color(0xFF9EA0A1),     // SoftBank Gray
    accent: Color(0xFF707070),      // Dark Accent
    background: Color(0xFFF8F8F8),  // Page Background
    surface: Color(0xFFFFFFFF),     // Card / Surface
    textMain: Color(0xFF000000),    // Main Text
    textSub: Color(0xFF707070),     // Sub Text
    divider: Color(0xFFE0E0E0),     // Divider Line
    disabled: Color(0xFFD3D3D3),    // Disabled
    hover: Color(0xFFC9CACA),       // Hover / Active
    orange: Color(0xFFF6A85B),      // 🍊 Soft Orange
    green: Color(0xFF7BC47F),       // 🌿 Soft Mint Green
  );

  /// 🌙 Dark Mode Colors
  static const dark = _AppPalette(
    primary: Color(0xFF9EA0A1),
    accent: Color(0xFF9EA0A1),
    background: Color(0xFF1E1E1E),
    surface: Color(0xFF2A2A2A),
    textMain: Color(0xFFFFFFFF),
    textSub: Color(0xFF9EA0A1),
    divider: Color(0xFF3C3C3C),
    disabled: Color(0xFF555555),
    hover: Color(0xFF707070),
    orange: Color(0xFFE38B41),      // 🍊 Muted Orange (Dark Mode)
    green: Color(0xFF6FBF73),       // 🌿 Fresh Green (Dark Mode)
  );
}

/// 내부 팔레트 클래스 (Light / Dark 공통 구조)
class _AppPalette {
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color textMain;
  final Color textSub;
  final Color divider;
  final Color disabled;
  final Color hover;
  final Color orange;
  final Color green;

  const _AppPalette({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textMain,
    required this.textSub,
    required this.divider,
    required this.disabled,
    required this.hover,
    required this.orange,
    required this.green,
  });
}
