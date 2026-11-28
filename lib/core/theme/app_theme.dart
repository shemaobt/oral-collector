import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shadows.dart';
import 'genre_colors.dart';
import 'screen_transition.dart';
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
      displayMedium: brush(
        base.displayMedium,
        screenTitleSize,
        screenTitleHeight,
      ),
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

  static const screenTitleSize = 42.0;
  static const screenTitleHeight = 0.95;

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

  static const _noTint = Colors.transparent;
  static const _topBarHeight = 64.0;
  static const _topBarLine = 1.5;

  static AppBarTheme _appBarTheme(AppColorSet c, TextTheme text) {
    return AppBarTheme(
      toolbarHeight: _topBarHeight,
      backgroundColor: c.background,
      foregroundColor: c.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: _noTint,
      centerTitle: false,
      titleTextStyle: text.headlineLarge,
      shape: Border(
        bottom: BorderSide(color: c.border, width: _topBarLine),
      ),
    );
  }

  static DialogThemeData _dialogTheme(AppColorSet c, TextTheme text) {
    return DialogThemeData(
      titleTextStyle: text.headlineLarge?.copyWith(
        fontSize: _questionTitleSize,
        height: 0.95,
      ),
      contentTextStyle: text.bodyMedium?.copyWith(
        fontSize: _menuTextSize,
        color: c.secondary,
      ),
      backgroundColor: c.card,
      surfaceTintColor: _noTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusScale.r24),
      ),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(AppColorSet c) {
    return BottomSheetThemeData(
      backgroundColor: c.card,
      modalBackgroundColor: c.card,
      surfaceTintColor: _noTint,
      showDragHandle: true,
      dragHandleColor: c.border,
      dragHandleSize: const Size(40, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RadiusScale.r28),
        ),
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme(AppColorSet c) {
    return SnackBarThemeData(
      backgroundColor: c.primary,
      actionTextColor: c.wood,
      contentTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c.onPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusScale.r16),
      ),
    );
  }

  static const _questionTitleSize = 30.0;
  static const _menuTextSize = 15.0;
  static const _menuRadius = 18.0;
  static const _menuRowHeight = 48.0;
  static const _menuRows = EdgeInsets.symmetric(vertical: 6);

  static final _menuShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_menuRadius),
  );

  static TextStyle _menuText(AppColorSet c) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _menuTextSize,
    fontWeight: FontWeight.w500,
    color: c.foreground,
  );

  static PopupMenuThemeData _popupMenuTheme(AppColorSet c, Color shadow) {
    return PopupMenuThemeData(
      color: c.card,
      surfaceTintColor: _noTint,
      shape: _menuShape,
      elevation: MenuShadow.elevation,
      shadowColor: shadow,
      menuPadding: _menuRows,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => _menuText(c).copyWith(
          color: states.contains(WidgetState.disabled)
              ? c.secondary
              : c.foreground,
        ),
      ),
    );
  }

  static MenuThemeData _menuTheme(AppColorSet c, Color shadow) {
    return MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(c.card),
        surfaceTintColor: WidgetStateProperty.all(_noTint),
        shape: WidgetStateProperty.all(_menuShape),
        elevation: WidgetStateProperty.all(MenuShadow.elevation),
        shadowColor: WidgetStateProperty.all(shadow),
        padding: WidgetStateProperty.all(_menuRows),
      ),
    );
  }

  static MenuButtonThemeData _menuButtonTheme(AppColorSet c) {
    return MenuButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(_menuText(c)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? c.secondary
              : c.foreground,
        ),
        minimumSize: WidgetStateProperty.all(const Size(0, _menuRowHeight)),
      ),
    );
  }

  static DividerThemeData _dividerTheme(AppColorSet c) {
    return DividerThemeData(color: c.border, thickness: 1);
  }

  static ChipThemeData _chipTheme(AppColorSet c) {
    return ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: c.primary,
      checkmarkColor: c.onPrimary,
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.onPrimary
              : c.foreground,
        ),
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: c.onPrimary,
      ),
      side: BorderSide(color: c.border, width: _buttonBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusScale.r20),
      ),
    );
  }

  static TabBarThemeData _tabBarTheme(AppColorSet c) {
    return TabBarThemeData(
      labelColor: c.accent,
      unselectedLabelColor: c.secondary,
      indicatorColor: c.accent,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: c.accent, width: 3),
      ),
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static SwitchThemeData _switchTheme(AppColorSet c) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.border,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  static CheckboxThemeData _checkboxTheme(AppColorSet c) {
    return CheckboxThemeData(
      checkColor: WidgetStateProperty.all(Colors.white),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.accent
            : Colors.transparent,
      ),
      side: BorderSide(color: c.border, width: _buttonBorder),
    );
  }

  static ProgressIndicatorThemeData _progressTheme(AppColorSet c) {
    return ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surfaceAlt,
      circularTrackColor: c.surfaceAlt,
    );
  }

  static SliderThemeData _sliderTheme(AppColorSet c) {
    return SliderThemeData(
      activeTrackColor: c.accent,
      inactiveTrackColor: c.border,
      thumbColor: c.card,
      overlayColor: c.accent.withValues(alpha: OpacityScale.o15),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      ThemeData.light().textTheme.apply(fontFamily: _fontFamily),
      AppColors.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      fontFamily: _fontFamily,
      extensions: const <ThemeExtension<dynamic>>[
        AppColors.light,
        GenreColors.light,
        AppSpacing.fallback,
        AppRadii.fallback,
        AppDurations.fallback,
        AppMotion.fallback,
        AppOpacity.fallback,
      ],
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
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
        outlineVariant: AppColors.border,
        surfaceContainerLowest: AppColors.card,
        surfaceContainerLow: AppColors.card,
        surfaceContainer: AppColors.surfaceAlt,
        surfaceContainerHigh: AppColors.surfaceAlt,
        surfaceContainerHighest: AppColors.pale,
      ),
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: ScreenTransition.phone,
      textTheme: textTheme,
      appBarTheme: _appBarTheme(AppColors.light, textTheme),
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
      dividerTheme: _dividerTheme(AppColors.light),
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
      chipTheme: _chipTheme(AppColors.light),
      dialogTheme: _dialogTheme(AppColors.light, textTheme),
      bottomSheetTheme: _bottomSheetTheme(AppColors.light),
      menuTheme: _menuTheme(AppColors.light, MenuShadow.light),
      menuButtonTheme: _menuButtonTheme(AppColors.light),
      popupMenuTheme: _popupMenuTheme(AppColors.light, MenuShadow.light),
      snackBarTheme: _snackBarTheme(AppColors.light),
      tabBarTheme: _tabBarTheme(AppColors.light),
      sliderTheme: _sliderTheme(AppColors.light),
      switchTheme: _switchTheme(AppColors.light),
      checkboxTheme: _checkboxTheme(AppColors.light),
      progressIndicatorTheme: _progressTheme(AppColors.light),
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
      splashFactory: NoSplash.splashFactory,
      fontFamily: _fontFamily,
      extensions: const <ThemeExtension<dynamic>>[
        AppColors.dark,
        GenreColors.dark,
        AppSpacing.fallback,
        AppRadii.fallback,
        AppDurations.fallback,
        AppMotion.fallback,
        AppOpacity.fallback,
      ],
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkSuccess,
        onSecondary: Colors.white,
        error: AppColors.darkError,
        onError: AppColors.darkOnPrimary,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkForeground,
        tertiary: AppColors.darkInfo,
        onTertiary: Colors.white,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorder,
        surfaceContainerLowest: AppColors.darkSurface,
        surfaceContainerLow: AppColors.darkSurface,
        surfaceContainer: AppColors.darkSurfaceAlt,
        surfaceContainerHigh: AppColors.darkSurfaceAlt,
        surfaceContainerHighest: AppColors.darkPale,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      pageTransitionsTheme: ScreenTransition.phone,
      textTheme: textTheme,
      appBarTheme: _appBarTheme(AppColors.dark, textTheme),
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
      dividerTheme: _dividerTheme(AppColors.dark),
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
      chipTheme: _chipTheme(AppColors.dark),
      dialogTheme: _dialogTheme(AppColors.dark, textTheme),
      bottomSheetTheme: _bottomSheetTheme(AppColors.dark),
      menuTheme: _menuTheme(AppColors.dark, MenuShadow.dark),
      menuButtonTheme: _menuButtonTheme(AppColors.dark),
      popupMenuTheme: _popupMenuTheme(AppColors.dark, MenuShadow.dark),
      snackBarTheme: _snackBarTheme(AppColors.dark),
      tabBarTheme: _tabBarTheme(AppColors.dark),
      sliderTheme: _sliderTheme(AppColors.dark),
      switchTheme: _switchTheme(AppColors.dark),
      checkboxTheme: _checkboxTheme(AppColors.dark),
      progressIndicatorTheme: _progressTheme(AppColors.dark),
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
