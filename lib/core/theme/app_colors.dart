import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color gradientStart = Color(0xFF6D28D9);
  static const Color gradientEnd   = Color(0xFFDB2777);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient profileBannerGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF131313)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient avatarRingGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color backgroundDark         = Color(0xFF131313);
  static const Color backgroundLight        = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow    = Color(0xFF1C1B1B);
  static const Color surfaceContainer       = Color(0xFF201F1F);
  static const Color surfaceContainerHigh   = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest= Color(0xFF353534);
  static const Color surfaceDark            = Color(0xFF131313);
  static const Color surfaceBright          = Color(0xFF3A3939);
  static const Color surfaceLight           = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight  = Color(0xFFF3F0F5);
  static const Color surfaceContainerHighLight = Color(0xFFEDE8F0);

  static const Color primary               = Color(0xFFD3BBFF);
  static const Color primaryContainer      = Color(0xFF7C3DE8);
  static const Color primaryContainerLight = Color(0xFF7C3AED);
  static const Color onPrimary             = Color(0xFF3F008D);
  static const Color onPrimaryContainer    = Color(0xFFEDE0FF);
  static const Color inversePrimary        = Color(0xFF7331DF);

  static const Color secondary            = Color(0xFFFFB1C7);
  static const Color secondaryContainer   = Color(0xFFBE0062);
  static const Color onSecondary          = Color(0xFF650031);
  static const Color onSecondaryContainer = Color(0xFFFFD0DC);

  static const Color onSurfaceDark         = Color(0xFFE5E2E1);
  static const Color onSurfaceVariantDark  = Color(0xFFCCC3D8);
  static const Color onSurfaceLight        = Color(0xFF111111);
  static const Color onSurfaceVariantLight = Color(0xFF555060);

  static const Color outline             = Color(0xFF958DA1);
  static const Color outlineVariant      = Color(0xFF4A4455);
  static const Color outlineVariantLight = Color(0xFFE5E5E5);

  static const Color error          = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError        = Color(0xFF690005);
  static const Color errorLight     = Color(0xFFB3261E);

  static const Color unreadTint       = Color(0xFF1A1214);
  static const Color navBarBackground = Color(0xFF0E0E0E);
  static const Color violetGlow       = Color(0x267C3AED);
  static const Color violetGlowStrong = Color(0x407C3AED);
  static const Color white            = Color(0xFFFFFFFF);
  static const Color black            = Color(0xFF000000);

  // ── Theme-aware — use these in build() methods only, never in const ──
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? backgroundDark : backgroundLight;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceContainerLow : surfaceLight;

  static Color cardHigh(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceContainerHigh : surfaceContainerHighLight;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? onSurfaceDark : onSurfaceLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? onSurfaceVariantDark : onSurfaceVariantLight;

  static Color input(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceContainerLowest : surfaceContainerLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? outlineVariant : outlineVariantLight;
}
