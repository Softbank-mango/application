import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTheme {

  // --- 🎨 라이트 모드 테마 ---
  static ThemeData get lightTheme {
    const palette = AppColors.light;
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Pretendard',
      useMaterial3: true,

      // 색상 스킴 (Color Scheme)
      colorScheme: ColorScheme.light(
        primary: palette.accent, // 앱의 주요 강조색 (버튼, 링크 등)
        secondary: palette.primary, // 보조색
        background: palette.background, // 앱 전체 배경
        surface: palette.surface, // 카드 배경
        onPrimary: Colors.white, // Primary 색상 위의 텍스트
        onSecondary: Colors.black,
        onBackground: palette.textMain,
        onSurface: palette.textMain,
        error: Colors.red[700]!,
        onError: Colors.white,
      ),

      // AppBar 테마
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface, // 흰색
        elevation: 0,
        surfaceTintColor: palette.surface,
        foregroundColor: palette.textMain, // 아이콘/텍스트 색상
        titleTextStyle: TextStyle(
          color: palette.textMain,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
      ),

      // 카드 테마
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: palette.divider, width: 1),
        ),
      ),

      // 텍스트 테마
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: palette.textMain, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: palette.textMain, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: palette.textMain, fontSize: 14),
        bodySmall: TextStyle(color: palette.textSub, fontSize: 12),
      ),

      // 하단 탭바 테마
      tabBarTheme: TabBarThemeData( // <-- [FIX] TabBarTheme -> TabBarThemeData
        indicatorColor: palette.accent,
        labelColor: palette.accent,
        unselectedLabelColor: palette.textSub,
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // 기타
      dividerColor: palette.divider,
      hintColor: palette.textSub,
    );
  }

  // --- 🌙 다크 모드 테마 ---
  static ThemeData get darkTheme {
    const palette = AppColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Pretendard',
      useMaterial3: true,

      // 색상 스킴
      colorScheme: ColorScheme.dark(
        primary: palette.accent,
        secondary: palette.primary,
        background: palette.background,
        surface: palette.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: palette.textMain,
        onSurface: palette.textMain,
        error: Colors.red[300]!,
        onError: Colors.black,
      ),

      // AppBar 테마
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        elevation: 0,
        surfaceTintColor: palette.surface,
        foregroundColor: palette.textMain,
        titleTextStyle: TextStyle(
          color: palette.textMain,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
      ),

      // 카드 테마
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: palette.divider, width: 1),
        ),
      ),

      // 텍스트 테마
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: palette.textMain, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: palette.textMain, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: palette.textMain, fontSize: 14),
        bodySmall: TextStyle(color: palette.textSub, fontSize: 12),
      ),

      // 하단 탭바 테마
      tabBarTheme: TabBarThemeData( // <-- [FIX] TabBarTheme -> TabBarThemeData
        indicatorColor: palette.accent,
        labelColor: palette.accent,
        unselectedLabelColor: palette.textSub,
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // 기타
      dividerColor: palette.divider,
      hintColor: palette.textSub,
    );
  }
}