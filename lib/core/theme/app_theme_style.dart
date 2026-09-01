import 'package:flutter/material.dart';

enum HeroCardStyle { ring, alertBanner, blobCard }

@immutable
class AppThemeStyle extends ThemeExtension<AppThemeStyle> {
  final ColorScheme colorScheme;
  final String fontFamily;
  final String displayFontFamily;
  final HeroCardStyle heroCardStyle;
  final bool showDecorativeShapes;
  final double cardRadius;
  final Gradient? heroGradient;
  final Color heroBackground;

  const AppThemeStyle({
    required this.colorScheme,
    required this.fontFamily,
    required this.displayFontFamily,
    required this.heroCardStyle,
    required this.showDecorativeShapes,
    required this.cardRadius,
    required this.heroGradient,
    required this.heroBackground,
  });

  @override
  AppThemeStyle copyWith({
    ColorScheme? colorScheme,
    String? fontFamily,
    String? displayFontFamily,
    HeroCardStyle? heroCardStyle,
    bool? showDecorativeShapes,
    double? cardRadius,
    Gradient? heroGradient,
    Color? heroBackground,
  }) {
    return AppThemeStyle(
      colorScheme: colorScheme ?? this.colorScheme,
      fontFamily: fontFamily ?? this.fontFamily,
      displayFontFamily: displayFontFamily ?? this.displayFontFamily,
      heroCardStyle: heroCardStyle ?? this.heroCardStyle,
      showDecorativeShapes: showDecorativeShapes ?? this.showDecorativeShapes,
      cardRadius: cardRadius ?? this.cardRadius,
      heroGradient: heroGradient ?? this.heroGradient,
      heroBackground: heroBackground ?? this.heroBackground,
    );
  }

  @override
  AppThemeStyle lerp(ThemeExtension<AppThemeStyle>? other, double t) {
    // Themes snap instantly on switch rather than animate-blending.
    return this;
  }
}
