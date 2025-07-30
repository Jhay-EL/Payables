import 'package:flutter/material.dart';

/// Material 3 Color System Implementation
/// This class provides Material 3 color roles, schemes, and adaptive color system
/// following the Material 3 design guidelines.
class Material3ColorSystem {
  // Material 3 Color Roles
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31111D);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color surface = Color(0xFFFFFBFE);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color inverseSurface = Color(0xFF313033);
  static const Color onInverseSurface = Color(0xFFF4EFF4);
  static const Color inversePrimary = Color(0xFFD0BCFF);

  static const Color surfaceTint = Color(0xFF6750A4);
  static const Color surfaceBright = Color(0xFFFFFBFE);
  static const Color surfaceDim = Color(0xFFDED8E1);

  // Dark Theme Color Roles
  static const Color primaryDark = Color(0xFFD0BCFF);
  static const Color onPrimaryDark = Color(0xFF381E72);
  static const Color primaryContainerDark = Color(0xFF4F378B);
  static const Color onPrimaryContainerDark = Color(0xFFEADDFF);

  static const Color secondaryDark = Color(0xFFCCC2DC);
  static const Color onSecondaryDark = Color(0xFF332D41);
  static const Color secondaryContainerDark = Color(0xFF4A4458);
  static const Color onSecondaryContainerDark = Color(0xFFE8DEF8);

  static const Color tertiaryDark = Color(0xFFEFB8C8);
  static const Color onTertiaryDark = Color(0xFF492532);
  static const Color tertiaryContainerDark = Color(0xFF633B48);
  static const Color onTertiaryContainerDark = Color(0xFFFFD8E4);

  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);

  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  static const Color surfaceVariantDark = Color(0xFF49454F);
  static const Color onSurfaceVariantDark = Color(0xFFCAC4D0);

  static const Color outlineDark = Color(0xFF938F99);
  static const Color outlineVariantDark = Color(0xFF49454F);

  static const Color shadowDark = Color(0xFF000000);
  static const Color scrimDark = Color(0xFF000000);
  static const Color inverseSurfaceDark = Color(0xFFE6E1E5);
  static const Color onInverseSurfaceDark = Color(0xFF313033);
  static const Color inversePrimaryDark = Color(0xFF6750A4);

  static const Color surfaceTintDark = Color(0xFFD0BCFF);
  static const Color surfaceBrightDark = Color(0xFF313033);
  static const Color surfaceDimDark = Color(0xFF1C1B1F);

  // Category Colors (Material 3 Design System)
  static const List<Color> categoryColors = [
    // Primary Colors
    Color(0xFF6750A4), // Primary Purple
    Color(0xFF006A6B), // Teal
    Color(0xFF8B5000), // Brown
    Color(0xFF006E1C), // Green
    // Secondary Colors
    Color(0xFF8E4EC6), // Secondary Purple
    Color(0xFF984061), // Pink
    Color(0xFF006B5D), // Dark Teal
    Color(0xFF795548), // Material Brown
    // Accent Colors
    Color(0xFFD32F2F), // Red
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFFF57C00), // Orange
    // Additional Material 3 Colors
    Color(0xFF7B1FA2), // Purple
    Color(0xFF00796B), // Teal
    Color(0xFF455A64), // Blue Grey
    Color(0xFF5D4037), // Brown
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Light Green
    Color(0xFF8BC34A), // Lime
    Color(0xFFCDDC39), // Yellow
    Color(0xFFFFEB3B), // Amber
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF9E9E9E), // Grey
    Color(0xFF607D8B), // Blue Grey
  ];

  static const List<Color> categoryBackgroundColors = [
    // Primary Background Colors
    Color(0xFFEADDFF), // Light Purple
    Color(0xFFA6F2FF), // Light Teal
    Color(0xFFFFDCC5), // Light Brown
    Color(0xFFA6F7B1), // Light Green
    // Secondary Background Colors
    Color(0xFFE8DEF8), // Light Secondary Purple
    Color(0xFFFFD8E4), // Light Pink
    Color(0xFFA6F2ED), // Light Dark Teal
    Color(0xFFEFEBE9), // Light Material Brown
    // Accent Background Colors
    Color(0xFFFFEBEE), // Light Red
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFE8F5E8), // Light Green
    Color(0xFFFFF3E0), // Light Orange
    // Additional Material 3 Background Colors
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFE0F2F1), // Light Teal
    Color(0xFFECEFF1), // Light Blue Grey
    Color(0xFFEFEBE9), // Light Brown
    Color(0xFFFCE4EC), // Light Pink
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFEDE7F6), // Light Deep Purple
    Color(0xFFE8EAF6), // Light Indigo
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFE1F5FE), // Light Light Blue
    Color(0xFFE0F2F1), // Light Cyan
    Color(0xFFE0F2F1), // Light Teal
    Color(0xFFE8F5E8), // Light Light Green
    Color(0xFFF1F8E9), // Light Lime
    Color(0xFFF9FBE7), // Light Yellow
    Color(0xFFFFFDE7), // Light Amber
    Color(0xFFFFF3E0), // Light Orange
    Color(0xFFFBE9E7), // Light Deep Orange
    Color(0xFFEFEBE9), // Light Brown
    Color(0xFFFAFAFA), // Light Grey
    Color(0xFFECEFF1), // Light Blue Grey
  ];

  /// Get Material 3 ColorScheme for light theme
  static ColorScheme getLightColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      inversePrimary: inversePrimary,
      surfaceTint: surfaceTint,
      surfaceBright: surfaceBright,
      surfaceDim: surfaceDim,
    );
  }

  /// Get Material 3 ColorScheme for dark theme
  static ColorScheme getDarkColorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryContainerDark,
      onPrimaryContainer: onPrimaryContainerDark,
      secondary: secondaryDark,
      onSecondary: onSecondaryDark,
      secondaryContainer: secondaryContainerDark,
      onSecondaryContainer: onSecondaryContainerDark,
      tertiary: tertiaryDark,
      onTertiary: onTertiaryDark,
      tertiaryContainer: tertiaryContainerDark,
      onTertiaryContainer: onTertiaryContainerDark,
      error: errorDark,
      onError: onErrorDark,
      errorContainer: errorContainerDark,
      onErrorContainer: onErrorContainerDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: onSurfaceVariantDark,
      outline: outlineDark,
      outlineVariant: outlineVariantDark,
      shadow: shadowDark,
      scrim: scrimDark,
      inverseSurface: inverseSurfaceDark,
      onInverseSurface: onInverseSurfaceDark,
      inversePrimary: inversePrimaryDark,
      surfaceTint: surfaceTintDark,
      surfaceBright: surfaceBrightDark,
      surfaceDim: surfaceDimDark,
    );
  }

  /// Get adaptive color based on brightness
  static Color getAdaptiveColor({
    required Color lightColor,
    required Color darkColor,
    required Brightness brightness,
  }) {
    return brightness == Brightness.light ? lightColor : darkColor;
  }

  /// Get category color with index
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  /// Get category background color with index
  static Color getCategoryBackgroundColor(int index) {
    return categoryBackgroundColors[index % categoryBackgroundColors.length];
  }

  /// Get category color pair (color and background)
  static List<Color> getCategoryColorPair(int index) {
    return [getCategoryColor(index), getCategoryBackgroundColor(index)];
  }

  /// Get surface color based on brightness
  static Color getSurfaceColor(Brightness brightness) {
    return brightness == Brightness.light ? surface : surfaceDark;
  }

  /// Get surface variant color based on brightness
  static Color getSurfaceVariantColor(Brightness brightness) {
    return brightness == Brightness.light ? surfaceVariant : surfaceVariantDark;
  }

  /// Get on surface color based on brightness
  static Color getOnSurfaceColor(Brightness brightness) {
    return brightness == Brightness.light ? onSurface : onSurfaceDark;
  }

  /// Get on surface variant color based on brightness
  static Color getOnSurfaceVariantColor(Brightness brightness) {
    return brightness == Brightness.light
        ? onSurfaceVariant
        : onSurfaceVariantDark;
  }

  /// Get outline color based on brightness
  static Color getOutlineColor(Brightness brightness) {
    return brightness == Brightness.light ? outline : outlineDark;
  }

  /// Get outline variant color based on brightness
  static Color getOutlineVariantColor(Brightness brightness) {
    return brightness == Brightness.light ? outlineVariant : outlineVariantDark;
  }

  /// Get primary color based on brightness
  static Color getPrimaryColor(Brightness brightness) {
    return brightness == Brightness.light ? primary : primaryDark;
  }

  /// Get primary container color based on brightness
  static Color getPrimaryContainerColor(Brightness brightness) {
    return brightness == Brightness.light
        ? primaryContainer
        : primaryContainerDark;
  }

  /// Get on primary color based on brightness
  static Color getOnPrimaryColor(Brightness brightness) {
    return brightness == Brightness.light ? onPrimary : onPrimaryDark;
  }

  /// Get on primary container color based on brightness
  static Color getOnPrimaryContainerColor(Brightness brightness) {
    return brightness == Brightness.light
        ? onPrimaryContainer
        : onPrimaryContainerDark;
  }

  /// Get secondary color based on brightness
  static Color getSecondaryColor(Brightness brightness) {
    return brightness == Brightness.light ? secondary : secondaryDark;
  }

  /// Get secondary container color based on brightness
  static Color getSecondaryContainerColor(Brightness brightness) {
    return brightness == Brightness.light
        ? secondaryContainer
        : secondaryContainerDark;
  }

  /// Get tertiary color based on brightness
  static Color getTertiaryColor(Brightness brightness) {
    return brightness == Brightness.light ? tertiary : tertiaryDark;
  }

  /// Get tertiary container color based on brightness
  static Color getTertiaryContainerColor(Brightness brightness) {
    return brightness == Brightness.light
        ? tertiaryContainer
        : tertiaryContainerDark;
  }

  /// Get error color based on brightness
  static Color getErrorColor(Brightness brightness) {
    return brightness == Brightness.light ? error : errorDark;
  }

  /// Get error container color based on brightness
  static Color getErrorContainerColor(Brightness brightness) {
    return brightness == Brightness.light ? errorContainer : errorContainerDark;
  }

  /// Get surface tint color based on brightness
  static Color getSurfaceTintColor(Brightness brightness) {
    return brightness == Brightness.light ? surfaceTint : surfaceTintDark;
  }

  /// Get surface bright color based on brightness
  static Color getSurfaceBrightColor(Brightness brightness) {
    return brightness == Brightness.light ? surfaceBright : surfaceBrightDark;
  }

  /// Get surface dim color based on brightness
  static Color getSurfaceDimColor(Brightness brightness) {
    return brightness == Brightness.light ? surfaceDim : surfaceDimDark;
  }

  /// Get shadow color based on brightness
  static Color getShadowColor(Brightness brightness) {
    return brightness == Brightness.light ? shadow : shadowDark;
  }

  /// Get scrim color based on brightness
  static Color getScrimColor(Brightness brightness) {
    return brightness == Brightness.light ? scrim : scrimDark;
  }

  /// Get inverse surface color based on brightness
  static Color getInverseSurfaceColor(Brightness brightness) {
    return brightness == Brightness.light ? inverseSurface : inverseSurfaceDark;
  }

  /// Get on inverse surface color based on brightness
  static Color getOnInverseSurfaceColor(Brightness brightness) {
    return brightness == Brightness.light
        ? onInverseSurface
        : onInverseSurfaceDark;
  }

  /// Get inverse primary color based on brightness
  static Color getInversePrimaryColor(Brightness brightness) {
    return brightness == Brightness.light ? inversePrimary : inversePrimaryDark;
  }
}
