import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Color(0xFF2E3440),
      primary: Color(0xFF2E3440),
      onPrimary: Color(0xFF7B7676),
      brightness: Brightness.dark,
    );

    final textTheme = TextTheme(
      headlineMedium: const TextStyle(fontFamily: 'Arkhamic', fontSize: 24.0),
      bodySmall: const TextStyle(
        fontFamily: 'Alegreya',
        fontStyle: FontStyle.italic,
        fontSize: 15.0,
        fontVariations: [FontVariation('wght', 450)],
      ),
    );

    final appBarTheme = AppBarTheme(titleTextStyle: textTheme.headlineMedium);

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: appBarTheme,
    );
  }
}
