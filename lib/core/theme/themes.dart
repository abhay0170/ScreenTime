import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme_style.dart';
import 'app_theme_variant.dart';

/// Merges a body [TextTheme] with a [TextTheme] used for display/headline
/// styles, so a theme can use two different font families.
TextTheme _mergeTextThemes({
  required TextTheme body,
  required TextTheme display,
}) {
  return body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge,
    headlineMedium: display.headlineMedium,
    headlineSmall: display.headlineSmall,
  );
}

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  required Color background,
  required TextTheme textTheme,
  required AppThemeStyle style,
}) {
  return ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.cardRadius),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    extensions: [style],
  );
}

final ThemeData materialFlowTheme = _buildTheme(
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF6750A4),
    onPrimary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
  ),
  background: const Color(0xFFF4F2FB),
  textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  style: AppThemeStyle(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6750A4),
      onPrimary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1C1B1F),
    ),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily!,
    displayFontFamily: GoogleFonts.plusJakartaSans().fontFamily!,
    heroCardStyle: HeroCardStyle.ring,
    showDecorativeShapes: false,
    cardRadius: 24,
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6750A4), Color(0xFF8B5CF6)],
    ),
    heroBackground: const Color(0xFF6750A4),
  ),
);

// Night Focus's ColorScheme.dark() explicitly pins outline/surface-variant
// tones too — left unset, they fall back to Material 3's baseline dark
// scheme (a purple-tinted neutral swatch) which doesn't match this theme's
// warm gold-on-near-black palette, especially for card borders.
const _nightFocusScheme = ColorScheme.dark(
  primary: Color(0xFFD4A63A),
  onPrimary: Color(0xFF17171B),
  surface: Color(0xFF232329),
  onSurface: Color(0xFFF5F5F5),
  onSurfaceVariant: Color(0xFF9A9AA2),
  error: Color(0xFFC2703D),
  outline: Color(0xFF5C5A54),
  outlineVariant: Color(0xFF38373A),
  surfaceContainerHighest: Color(0xFF2C2C31),
);

final ThemeData nightFocusTheme = _buildTheme(
  colorScheme: _nightFocusScheme,
  background: const Color(0xFF17171B),
  textTheme: _mergeTextThemes(
    body: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    display: GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
  ),
  style: AppThemeStyle(
    colorScheme: _nightFocusScheme,
    fontFamily: GoogleFonts.inter().fontFamily!,
    displayFontFamily: GoogleFonts.spaceGrotesk().fontFamily!,
    heroCardStyle: HeroCardStyle.alertBanner,
    showDecorativeShapes: false,
    cardRadius: 12,
    heroGradient: null,
    heroBackground: const Color(0xFF17171B),
  ),
);

// Calm Balance's ColorScheme.light() explicitly pins its neutral/outline
// tones. Left unset, they fall back to Material 3's baseline light scheme —
// a cool purple-gray swatch — which reads muddy against this theme's warm
// cream/sage/terracotta palette (most visibly in the ~40%-opacity card
// backgrounds that composite onSurfaceVariant-family colors over the cream
// scaffold background).
const _calmBalanceScheme = ColorScheme.light(
  primary: Color(0xFF7CAE86),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFD99A6C),
  onSecondary: Color(0xFFFFFFFF),
  // Approximates a 55%-opacity white card over the #F6EEE0 background.
  surface: Color(0xFFFBF7F1),
  onSurface: Color(0xFF3A2E20),
  onSurfaceVariant: Color(0xFF7D7161),
  outline: Color(0xFFA69B87),
  outlineVariant: Color(0xFFE2D9C5),
  surfaceContainerHighest: Color(0xFFEFE7D8),
);

final ThemeData calmBalanceTheme = _buildTheme(
  colorScheme: _calmBalanceScheme,
  background: const Color(0xFFF6EEE0),
  textTheme: _mergeTextThemes(
    body: GoogleFonts.workSansTextTheme(),
    display: GoogleFonts.newsreaderTextTheme(),
  ),
  style: AppThemeStyle(
    colorScheme: _calmBalanceScheme,
    fontFamily: GoogleFonts.workSans().fontFamily!,
    displayFontFamily: GoogleFonts.newsreader().fontFamily!,
    heroCardStyle: HeroCardStyle.blobCard,
    showDecorativeShapes: true,
    cardRadius: 22,
    heroGradient: null,
    heroBackground: const Color(0xFFF6EEE0),
  ),
);

ThemeData themeForVariant(AppThemeVariant variant) {
  switch (variant) {
    case AppThemeVariant.materialFlow:
      return materialFlowTheme;
    case AppThemeVariant.nightFocus:
      return nightFocusTheme;
    case AppThemeVariant.calmBalance:
      return calmBalanceTheme;
  }
}
