import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'genre_colors.dart';
import 'tokens.dart';

const _fontFamily = 'Montserrat';
const _brushFamily = 'CaveatBrush';

abstract class AppButtonStyles {
  static ButtonStyle danger(BuildContext context) {
    final c = AppColors.of(context);
    return AppTheme._filledStyle(c, c.error);
  }
}

abstract class AppTheme {
  static TextStyle _brushStyle(double size, double height, Color fg) {
    return TextStyle(
      fontFamily: _brushFamily,
      fontFamilyFallback: const [_fontFamily],
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      fontSize: size,
      letterSpacing: 0,
      height: height,
      color: fg,
    );
  }

  static TextStyle _sansStyle(
    double size,
    FontWeight weight,
    double height,
    Color fg,
  ) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: weight,
      fontStyle: FontStyle.normal,
      fontSize: size,
      letterSpacing: 0,
      height: height,
      color: fg,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color fg) {
    TextStyle? brush(TextStyle? s, double size, double height) =>
        s?.merge(_brushStyle(size, height, fg));
    TextStyle? sans(TextStyle? s, double size, FontWeight w, double height) =>
        s?.merge(_sansStyle(size, w, height, fg));

    return base.copyWith(
      displayLarge: brush(base.displayLarge, 44, 0.92),
      displayMedium: brush(base.displayMedium, 36, 0.92),
      displaySmall: brush(base.displaySmall, 28, 1),
      headlineLarge: brush(base.headlineLarge, 28, 1),
      headlineMedium: brush(base.headlineMedium, 23, 1),
      headlineSmall: sans(base.headlineSmall, 16, FontWeight.w700, 1.25),
      titleLarge: sans(base.titleLarge, 16, FontWeight.w700, 1.25),
      titleMedium: sans(base.titleMedium, 14, FontWeight.w700, 1.25),
      titleSmall: sans(base.titleSmall, 14, FontWeight.w600, 1.3),
      bodyLarge: sans(base.bodyLarge, 16, FontWeight.w500, 1.5),
      bodyMedium: sans(base.bodyMedium, 14, FontWeight.w500, 1.5),
      bodySmall: sans(base.bodySmall, 13, FontWeight.w500, 1.4),
      labelLarge: sans(base.labelLarge, 14, FontWeight.w700, 1.3),
      labelMedium: sans(base.labelMedium, 12, FontWeight.w700, 1.3),
      labelSmall: sans(base.labelSmall, 11, FontWeight.w700, 1.25),
    );
  }

  static const _buttonHeight = 46.0;
  static const _buttonBorder = 1.5;
  static const _iconButtonSize = 44.0;
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: SpacingScale.s20,
  );

  static ButtonStyle _filledStyle(AppColorSet c, Color fill) {
    return FilledButton.styleFrom(
      foregroundColor: c.background,
      disabledBackgroundColor: c.surfaceAlt,
      disabledForegroundColor: c.secondary,
      minimumSize: const Size(0, _buttonHeight),
      padding: _buttonPadding,
      shape: const StadiumBorder(),
      elevation: 0,
    ).copyWith(backgroundColor: _fill(c, fill));
  }

  static WidgetStateProperty<Color> _fill(AppColorSet c, Color fill) {
    return WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? c.surfaceAlt : fill,
    );
  }

  static ButtonStyle _outlinedStyle(AppColorSet c) {
    return OutlinedButton.styleFrom(
      foregroundColor: c.primary,
      minimumSize: const Size(0, _buttonHeight),
      padding: _buttonPadding,
      side: BorderSide(color: c.border, width: _buttonBorder),
      shape: const StadiumBorder(),
    );
  }

  static ButtonStyle _iconStyle(AppColorSet c) {
    return IconButton.styleFrom(
      fixedSize: const Size.square(_iconButtonSize),
      side: BorderSide(color: c.border, width: _buttonBorder),
      shape: const CircleBorder(),
    );
  }

  static TextButtonThemeData _lightTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static const _fieldBorder = 1.5;

  static InputDecorationTheme _inputDecorationTheme(AppColorSet c) {
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(RadiusScale.r16),
      borderSide: BorderSide(color: color, width: _fieldBorder),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? c.surfaceAlt : c.card,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: outline(c.border),
      enabledBorder: outline(c.border),
      disabledBorder: outline(c.border),
      focusedBorder: outline(c.primary),
      errorBorder: outline(c.error),
      focusedErrorBorder: outline(c.error),
      hintStyle: TextStyle(color: c.secondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s16,
        vertical: SpacingScale.s16,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      ThemeData.light().textTheme.apply(fontFamily: _fontFamily),
      AppColors.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      extensions: const <ThemeExtension<dynamic>>[
        AppColors.light,
        GenreColors.light,
        AppSpacing.fallback,
        AppRadii.fallback,
        AppDurations.fallback,
        AppOpacity.fallback,
      ],
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.foreground,
        onSurfaceVariant: AppColors.secondary,
        tertiary: AppColors.info,
        onTertiary: AppColors.foreground,
        outline: AppColors.border,
        outlineVariant: AppColors.outlineVariant,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineLarge,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: OpacityScale.o50),
            width: 1,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: AppColors.brandVerde.withValues(alpha: OpacityScale.o06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r16),
          side: BorderSide(
            color: AppColors.border.withValues(alpha: OpacityScale.o55),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledStyle(AppColors.light, AppColors.light.accent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledStyle(AppColors.light, AppColors.light.accent),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(AppColors.light),
      ),
      iconButtonTheme: IconButtonThemeData(style: _iconStyle(AppColors.light)),
      textButtonTheme: _lightTextButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(AppColors.light),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.foreground.withValues(
          alpha: OpacityScale.o50,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.card,
        selectedIconTheme: const IconThemeData(color: AppColors.accent),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.secondary.withValues(alpha: OpacityScale.o60),
        ),
        indicatorColor: AppColors.accent.withValues(alpha: OpacityScale.o12),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border.withValues(alpha: OpacityScale.o40),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.secondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        side: BorderSide(
          color: AppColors.border.withValues(alpha: OpacityScale.o55),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r20),
        ),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: textTheme.headlineLarge,
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: AppColors.brandVerde.withValues(alpha: OpacityScale.o08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r20),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.card,
        elevation: 3,
        modalElevation: 3,
        shadowColor: AppColors.brandVerde.withValues(alpha: OpacityScale.o08),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RadiusScale.r20),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.card),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(3),
          shadowColor: WidgetStateProperty.all(
            AppColors.brandVerde.withValues(alpha: OpacityScale.o08),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusScale.r12),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: AppColors.brandVerde.withValues(alpha: OpacityScale.o08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighest,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r12),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.foreground.withValues(
          alpha: OpacityScale.o40,
        ),
        indicatorColor: AppColors.accent,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border.withValues(
          alpha: OpacityScale.o40,
        ),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: OpacityScale.o15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.switchThumbUnselected;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: OpacityScale.o40);
          }
          return AppColors.border.withValues(alpha: OpacityScale.o30);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 4,
        hoverElevation: 6,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
      ThemeData.dark().textTheme.apply(fontFamily: _fontFamily),
      AppColors.darkForeground,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      extensions: const <ThemeExtension<dynamic>>[
        AppColors.dark,
        GenreColors.dark,
        AppSpacing.fallback,
        AppRadii.fallback,
        AppDurations.fallback,
        AppOpacity.fallback,
      ],
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.darkSuccess,
        onSecondary: Colors.white,
        error: AppColors.darkError,
        onError: Colors.white,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkForeground,
        tertiary: AppColors.darkInfo,
        onTertiary: Colors.white,
        outline: AppColors.darkBorder,
        surfaceContainerHighest: AppColors.darkSurface,
        surfaceContainerLow: AppColors.darkSurfaceAlt,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkForeground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineLarge,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: OpacityScale.o40),
            width: 1,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 1,
        shadowColor: AppColors.darkBorder.withValues(alpha: OpacityScale.o40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledStyle(AppColors.dark, AppColors.dark.accent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledStyle(AppColors.dark, AppColors.dark.accent),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(AppColors.dark),
      ),
      iconButtonTheme: IconButtonThemeData(style: _iconStyle(AppColors.dark)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          minimumSize: const Size(0, 48),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(AppColors.dark),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkForeground.withValues(
          alpha: OpacityScale.o40,
        ),
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: AppColors.darkPrimary),
        unselectedIconTheme: IconThemeData(
          color: AppColors.darkSecondary.withValues(alpha: OpacityScale.o60),
        ),
        indicatorColor: AppColors.darkPrimary.withValues(
          alpha: OpacityScale.o10,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder.withValues(alpha: OpacityScale.o30),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkForeground,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r20),
        ),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: textTheme.headlineLarge,
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r12),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.darkPrimary,
        unselectedLabelColor: AppColors.darkForeground.withValues(
          alpha: OpacityScale.o40,
        ),
        indicatorColor: AppColors.darkPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.darkPrimary,
        inactiveTrackColor: AppColors.darkBorder,
        thumbColor: AppColors.darkPrimary,
        overlayColor: AppColors.darkPrimary.withValues(alpha: OpacityScale.o15),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r16),
        ),
      ),
    );
  }
}
