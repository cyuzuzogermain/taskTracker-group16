import 'package:flutter/material.dart';

/// The app's colour palette.
class AppColors {
  static const Color primary = Color(0xFF1F3A5F); // Ink Navy
  static const Color primaryTint = Color(0xFFE6ECF4); // selected chips, nav
  static const Color background = Color(0xFFF6F7F9); // screen background
  static const Color surface = Color(0xFFFFFFFF); // cards, inputs
  static const Color border = Color(0xFFE3E6EB); // cards, dividers
  static const Color borderStrong = Color(0xFF8A93A0); // inputs, chips
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF5B6472);
  static const Color error = Color(0xFFB3261E);
  static const Color errorTint = Color(0xFFFDECEA);
}

/// Spacing scale. Use these instead of typing numbers into padding.
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radius values.
class AppRadius {
  static const double card = 12;
  static const double control = 8; // inputs, chips, buttons
  static const double fab = 16;
}

/// Builds the single theme used by the whole app.
class AppTheme {
  /// Must match the family name declared under `fonts:` in pubspec.yaml.
  static const String fontFamily = 'IBMPlexSans';

  /// One text style in IBM Plex Sans. [lineHeight] is in pixels.
  static TextStyle _text(
    double size,
    double lineHeight,
    FontWeight weight, {
    Color color = AppColors.textPrimary,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
    );
  }

  /// A 1px (or thicker) rounded border for text fields.
  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.textSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.primaryTint,
      onSecondaryContainer: AppColors.primary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorTint,
      onErrorContainer: AppColors.error,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainerHighest: Color(0xFFEEF0F3),
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
      // Stops Material 3 from washing surfaces with the primary colour.
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      displaySmall: _text(32, 40, FontWeight.w600), // big numbers
      headlineMedium: _text(28, 36, FontWeight.w600),
      headlineSmall: _text(24, 32, FontWeight.w600), // screen titles
      titleLarge: _text(18, 24, FontWeight.w600), // section headings
      titleMedium: _text(16, 22, FontWeight.w600), // card titles
      titleSmall: _text(14, 20, FontWeight.w600),
      bodyLarge: _text(16, 24, FontWeight.w400), // input text
      bodyMedium: _text(14, 20, FontWeight.w400), // default text
      bodySmall: _text(12, 16, FontWeight.w400,
          color: AppColors.textSecondary), // captions
      labelLarge: _text(14, 20, FontWeight.w500), // buttons
      labelMedium: _text(12, 16, FontWeight.w600), // chips
      labelSmall: _text(12, 16, FontWeight.w500), // nav labels
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );
    const buttonSize = Size.fromHeight(48);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),

      // Flat white cards with a thin border instead of a shadow.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(14),
        hintStyle:
            textTheme.bodyLarge!.copyWith(color: AppColors.textSecondary),
        labelStyle:
            textTheme.bodyLarge!.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle:
            textTheme.labelLarge!.copyWith(color: AppColors.primary),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall!.copyWith(color: AppColors.error),
        border: _inputBorder(AppColors.borderStrong),
        enabledBorder: _inputBorder(AppColors.borderStrong),
        focusedBorder: _inputBorder(AppColors.primary, 2),
        errorBorder: _inputBorder(AppColors.error, 2),
        focusedErrorBorder: _inputBorder(AppColors.error, 2),
        disabledBorder: _inputBorder(AppColors.border),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryTint,
        checkmarkColor: AppColors.primary,
        labelStyle: textTheme.labelLarge,
        shape: controlShape,
        // The border turns navy when the chip is selected.
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.borderStrong,
          ),
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // FilledButton is the app's primary button.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: buttonSize,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: buttonSize,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.fab)),
        ),
      ),

      // Bottom navigation: the selected tab is navy, the others grey.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryTint,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: Colors.white),
        shape: controlShape,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryTint,
        linearMinHeight: 8,
      ),
    );
  }
}
