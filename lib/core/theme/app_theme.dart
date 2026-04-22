import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF14B8A6); // Teal
  static const Color surface = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const Color accent =
      Color(0xFFFBBF24); // Amber (Seýil-Et action color)

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surface,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          onPrimary: Colors.black,
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          bodySmall: TextStyle(
            color: textSecondary,
            fontSize: 12,
          ),
        ),
        extensions: const [
          AppColors(),
        ],
      );
}

/// Typed color extension so widgets can do: Theme.of(ctx).appColors.accent
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    this.accent = const Color(0xFFFBBF24),
    this.cardBg = const Color(0xFF1E293B),
    this.textSecondary = const Color(0xFF94A3B8),
    this.shimmer = const Color(0xFF334155),
  });

  final Color accent;
  final Color cardBg;
  final Color textSecondary;
  final Color shimmer;

  @override
  AppColors copyWith({
    Color? accent,
    Color? cardBg,
    Color? textSecondary,
    Color? shimmer,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      cardBg: cardBg ?? this.cardBg,
      textSecondary: textSecondary ?? this.textSecondary,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;

    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }
}
