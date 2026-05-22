import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Paleta Modo Iglesia — OLED puro, alto contraste, sin luz que ilumine el rostro
const kOledBlack   = Color(0xFF000000);
const kSurface     = Color(0xFF0C0C0C);
const kCard        = Color(0xFF111111);
const kBorder      = Color(0xFF1E1E1E);
const kTextPrimary = Color(0xFFE6E6E6);
const kTextMuted   = Color(0xFF5A5A5A);
const kGold        = Color(0xFF9B7B3A); // acento dorado litúrgico
const kPanic       = Color(0xFFB02020); // rojo Botón de Pánico

ThemeData buildChurchTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kOledBlack,
      colorScheme: const ColorScheme.dark(
        surface: kOledBlack,
        surfaceContainerHighest: kCard,
        primary: kGold,
        onPrimary: Colors.black,
        onSurface: kTextPrimary,
        outline: kBorder,
        error: kPanic,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kOledBlack,
        foregroundColor: kTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: kTextPrimary, fontSize: 15, height: 1.55),
        bodyMedium: TextStyle(color: kTextPrimary, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: kTextMuted, fontSize: 12),
        titleMedium: TextStyle(
          color: kTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(color: kTextMuted, fontSize: 11),
      ),
      dividerColor: kBorder,
      dividerTheme: const DividerThemeData(color: kBorder, space: 1),
      dialogTheme: const DialogThemeData(
        backgroundColor: kCard,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: kTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: kTextMuted, fontSize: 14, height: 1.5),
      ),
    );
