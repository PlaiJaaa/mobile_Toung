import 'package:flutter/material.dart';

import 'color.dart';

// ธีมสว่างและธีมมืดของแอป (เลือกใช้ผ่าน themeMode ใน main.dart)
ThemeData lightTheme = buildTheme(Brightness.light);
ThemeData darkTheme = buildTheme(Brightness.dark);

// สร้าง ThemeData จากความสว่างที่ส่งเข้ามา เพื่อให้ธีมสว่าง/มืดหน้าตาไปทางเดียวกัน
ThemeData buildTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;

  // ชุดสี Material 3 สร้างจากสีหลักสีเดียว
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: brightness,
  );

  // สีพื้นหลังหน้าจอ และสีพื้นของการ์ด
  final Color backgroundColor = isDark
      ? const Color(0xFF0D1519)
      : const Color(0xFFF3F7F9);
  final Color cardColor = isDark ? const Color(0xFF162127) : Colors.white;
  final Color borderColor = isDark
      ? const Color(0xFF26343B)
      : const Color(0xFFDCE5EA);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Prompt', // ฟอนต์ภาษาไทย ประกาศไว้ใน pubspec.yaml
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundColor,
    dividerColor: borderColor,

    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Prompt',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
    ),

    // หน้าตาช่องกรอกข้อมูลทั้งแอป
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Prompt',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: cardColor,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Prompt',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Prompt', fontSize: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(
        fontFamily: 'Prompt',
        fontSize: 14,
        color: Colors.white,
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),

    // แถบแท็บในหน้ารายละเอียดทริป
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      dividerColor: borderColor,
      labelStyle: const TextStyle(
        fontFamily: 'Prompt',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Prompt', fontSize: 14),
    ),

    chipTheme: ChipThemeData(
      labelStyle: const TextStyle(fontFamily: 'Prompt', fontSize: 13),
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
