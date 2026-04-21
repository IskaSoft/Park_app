import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primary = Color.fromARGB(255, 52, 52, 73);
  static const Color _accent = Color(0xFFE94560);
  static const Color _surface = Color(0xFF16213E);
  static const Color _cardBg = Color(0xFF0F3460);
  static const Color _textPrimary = Color(0xFFEEEEEE);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _primary,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _surface,
          onPrimary: Colors.white,
          onSurface: _textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: _textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: _cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          bodySmall: TextStyle(
            color: _textSecondary,
            fontSize: 12,
          ),
        ),
        extensions: const [AppColors()],
      );
}

/// Typed color extension so widgets can do: Theme.of(ctx).appColors.accent
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    this.accent = const Color(0xFFE94560),
    this.cardBg = const Color(0xFF0F3460),
    this.textSecondary = const Color(0xFF9E9E9E),
    this.shimmer = const Color(0xFF1E2A4A),
  });

  final Color accent;
  final Color cardBg;
  final Color textSecondary;
  final Color shimmer;

  @override
  AppColors copyWith(
      {Color? accent, Color? cardBg, Color? textSecondary, Color? shimmer}) {
    return AppColors(
      accent: accent ?? this.accent,
      cardBg: cardBg ?? this.cardBg,
      textSecondary: textSecondary ?? this.textSecondary,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) => this;
}

extension ThemeDataX on ThemeData {
  AppColors get appColors => extension<AppColors>() ?? const AppColors();
}
