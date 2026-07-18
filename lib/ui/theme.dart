import 'package:flutter/material.dart';

ThemeData buildYuXinTheme() {
  const Color seed = Color(0xFF7A78F2);
  const Color surface = Color(0xFFFFFCFF);
  const Color background = Color(0xFFF4F5FF);
  final Color white92 = Colors.white.withOpacity(0.92);
  final Color white94 = Colors.white.withOpacity(0.94);
  final Color primary12 = seed.withOpacity(0.12);

  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(surface: surface);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: white92,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white94,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: white92,
      indicatorColor: primary12,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
