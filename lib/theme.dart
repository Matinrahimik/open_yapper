import "package:flutter/material.dart";

import 'theme/typography.dart';

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  /// Creates a MaterialTheme with M3 typography tokens.
  static MaterialTheme withTypography({Color? bodyColor, Color? displayColor}) {
    return MaterialTheme(
      TypographyTokens.textTheme(
        bodyColor: bodyColor,
        displayColor: displayColor,
      ),
    );
  }

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff88511d),
      surfaceTint: Color(0xff88511d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffffdcc2),
      onPrimaryContainer: Color(0xff6c3a06),
      secondary: Color(0xff745944),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffffdcc2),
      onSecondaryContainer: Color(0xff5a422e),
      tertiary: Color(0xff5c6237),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffe0e7b1),
      onTertiaryContainer: Color(0xff444a22),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f5),
      onSurface: Color(0xff221a14),
      onSurfaceVariant: Color(0xff51443b),
      outline: Color(0xff847469),
      outlineVariant: Color(0xffd6c3b6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff382f28),
      inversePrimary: Color(0xffffb77b),
      primaryFixed: Color(0xffffdcc2),
      onPrimaryFixed: Color(0xff2e1500),
      primaryFixedDim: Color(0xffffb77b),
      onPrimaryFixedVariant: Color(0xff6c3a06),
      secondaryFixed: Color(0xffffdcc2),
      onSecondaryFixed: Color(0xff2a1707),
      secondaryFixedDim: Color(0xffe3c0a6),
      onSecondaryFixedVariant: Color(0xff5a422e),
      tertiaryFixed: Color(0xffe0e7b1),
      onTertiaryFixed: Color(0xff191e00),
      tertiaryFixedDim: Color(0xffc4cb97),
      onTertiaryFixedVariant: Color(0xff444a22),
      surfaceDim: Color(0xffe7d7cd),
      surfaceBright: Color(0xfffff8f5),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff1e9),
      surfaceContainer: Color(0xfffbebe1),
      surfaceContainerHigh: Color(0xfff5e5db),
      surfaceContainerHighest: Color(0xffefe0d6),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff552b00),
      surfaceTint: Color(0xff88511d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff99602a),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff48311f),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff846751),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff333912),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff6a7144),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f5),
      onSurface: Color(0xff17100a),
      onSurfaceVariant: Color(0xff40342b),
      outline: Color(0xff5d5046),
      outlineVariant: Color(0xff796a5f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff382f28),
      inversePrimary: Color(0xffffb77b),
      primaryFixed: Color(0xff99602a),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff7d4814),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff846751),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff694f3b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff6a7144),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff52582e),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffd3c4ba),
      surfaceBright: Color(0xfffff8f5),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff1e9),
      surfaceContainer: Color(0xfff5e5db),
      surfaceContainerHigh: Color(0xffe9dad0),
      surfaceContainerHighest: Color(0xffdecfc5),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff462300),
      surfaceTint: Color(0xff88511d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6f3d08),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3d2816),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5d4430),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff292f09),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff464c24),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f5),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff352a21),
      outlineVariant: Color(0xff54473d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff382f28),
      inversePrimary: Color(0xffffb77b),
      primaryFixed: Color(0xff6f3d08),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff502900),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5d4430),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff442e1b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff464c24),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff30360f),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc4b6ad),
      surfaceBright: Color(0xfffff8f5),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffeeee4),
      surfaceContainer: Color(0xffefe0d6),
      surfaceContainerHigh: Color(0xffe1d2c8),
      surfaceContainerHighest: Color(0xffd3c4ba),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffb77b),
      surfaceTint: Color(0xffffb77b),
      onPrimary: Color(0xff4d2700),
      primaryContainer: Color(0xff6c3a06),
      onPrimaryContainer: Color(0xffffdcc2),
      secondary: Color(0xffe3c0a6),
      onSecondary: Color(0xff412c19),
      secondaryContainer: Color(0xff5a422e),
      onSecondaryContainer: Color(0xffffdcc2),
      tertiary: Color(0xffc4cb97),
      onTertiary: Color(0xff2e330d),
      tertiaryContainer: Color(0xff444a22),
      onTertiaryContainer: Color(0xffe0e7b1),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff19120c),
      onSurface: Color(0xffefe0d6),
      onSurfaceVariant: Color(0xffd6c3b6),
      outline: Color(0xff9e8e82),
      outlineVariant: Color(0xff51443b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffefe0d6),
      inversePrimary: Color(0xff88511d),
      primaryFixed: Color(0xffffdcc2),
      onPrimaryFixed: Color(0xff2e1500),
      primaryFixedDim: Color(0xffffb77b),
      onPrimaryFixedVariant: Color(0xff6c3a06),
      secondaryFixed: Color(0xffffdcc2),
      onSecondaryFixed: Color(0xff2a1707),
      secondaryFixedDim: Color(0xffe3c0a6),
      onSecondaryFixedVariant: Color(0xff5a422e),
      tertiaryFixed: Color(0xffe0e7b1),
      onTertiaryFixed: Color(0xff191e00),
      tertiaryFixedDim: Color(0xffc4cb97),
      onTertiaryFixedVariant: Color(0xff444a22),
      surfaceDim: Color(0xff19120c),
      surfaceBright: Color(0xff413731),
      surfaceContainerLowest: Color(0xff140d08),
      surfaceContainerLow: Color(0xff221a14),
      surfaceContainer: Color(0xff261e18),
      surfaceContainerHigh: Color(0xff312822),
      surfaceContainerHighest: Color(0xff3c332c),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffd4b4),
      surfaceTint: Color(0xffffb77b),
      onPrimary: Color(0xff3d1e00),
      primaryContainer: Color(0xffc3824a),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfffad5ba),
      onSecondary: Color(0xff352110),
      secondaryContainer: Color(0xffaa8b73),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffdae1ab),
      onTertiary: Color(0xff232804),
      tertiaryContainer: Color(0xff8e9565),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff19120c),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffecd9cc),
      outline: Color(0xffc1afa2),
      outlineVariant: Color(0xff9e8d82),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffefe0d6),
      inversePrimary: Color(0xff6d3b07),
      primaryFixed: Color(0xffffdcc2),
      onPrimaryFixed: Color(0xff1f0c00),
      primaryFixedDim: Color(0xffffb77b),
      onPrimaryFixedVariant: Color(0xff552b00),
      secondaryFixed: Color(0xffffdcc2),
      onSecondaryFixed: Color(0xff1e0d01),
      secondaryFixedDim: Color(0xffe3c0a6),
      onSecondaryFixedVariant: Color(0xff48311f),
      tertiaryFixed: Color(0xffe0e7b1),
      onTertiaryFixed: Color(0xff0f1300),
      tertiaryFixedDim: Color(0xffc4cb97),
      onTertiaryFixedVariant: Color(0xff333912),
      surfaceDim: Color(0xff19120c),
      surfaceBright: Color(0xff4c433c),
      surfaceContainerLowest: Color(0xff0c0603),
      surfaceContainerLow: Color(0xff241c16),
      surfaceContainer: Color(0xff2f2620),
      surfaceContainerHigh: Color(0xff3a312a),
      surfaceContainerHighest: Color(0xff453c35),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffede1),
      surfaceTint: Color(0xffffb77b),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xfffcb376),
      onPrimaryContainer: Color(0xff170700),
      secondary: Color(0xffffede1),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffdfbca2),
      onSecondaryContainer: Color(0xff170700),
      tertiary: Color(0xffeef5bd),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffc0c793),
      onTertiaryContainer: Color(0xff0a0d00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff19120c),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffffede1),
      outlineVariant: Color(0xffd2bfb2),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffefe0d6),
      inversePrimary: Color(0xff6d3b07),
      primaryFixed: Color(0xffffdcc2),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffffb77b),
      onPrimaryFixedVariant: Color(0xff1f0c00),
      secondaryFixed: Color(0xffffdcc2),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffe3c0a6),
      onSecondaryFixedVariant: Color(0xff1e0d01),
      tertiaryFixed: Color(0xffe0e7b1),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffc4cb97),
      onTertiaryFixedVariant: Color(0xff0f1300),
      surfaceDim: Color(0xff19120c),
      surfaceBright: Color(0xff584e47),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff261e18),
      surfaceContainer: Color(0xff382f28),
      surfaceContainerHigh: Color(0xff433a33),
      surfaceContainerHighest: Color(0xff4f453e),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
