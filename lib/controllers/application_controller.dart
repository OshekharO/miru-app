import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/utils/miru_storage.dart';

class ApplicationController extends GetxController {
  static get find => Get.find();

  final themeText = "system".obs;
  final materialYouColors = false.obs;
  final androidNavigationLabels = 'selected'.obs;

  @override
  void onInit() {
    themeText.value = MiruStorage.getSetting(SettingKey.theme);
    materialYouColors.value = MiruStorage.getSetting(
      SettingKey.materialYouColors,
    );
    if (Platform.isAndroid) {
      androidNavigationLabels.value =
          MiruStorage.getSetting(SettingKey.androidNavigationLabels) ??
              'selected';
    }
    super.onInit();
  }

  ThemeData mobileLightTheme(
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  ) {
    switch (themeText.value) {
      case "black":
        return _blackTheme(_dynamicScheme(darkDynamic));
      default:
        return _materialTheme(Brightness.light, _dynamicScheme(lightDynamic));
    }
  }

  ThemeData mobileDarkTheme(ColorScheme? darkDynamic) {
    return _materialTheme(Brightness.dark, _dynamicScheme(darkDynamic));
  }

  ColorScheme? _dynamicScheme(ColorScheme? scheme) {
    return materialYouColors.value ? scheme : null;
  }

  ThemeData _materialTheme(Brightness brightness, ColorScheme? colorScheme) {
    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final effectiveScheme = colorScheme ?? baseTheme.colorScheme;

    return _applyM3ExpressiveTheme(baseTheme, effectiveScheme);
  }

  ThemeData _applyM3ExpressiveTheme(
    ThemeData baseTheme,
    ColorScheme colorScheme,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      dialogTheme: DialogThemeData(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surfaceContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        modalBackgroundColor: colorScheme.surfaceContainerHigh,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        indicatorShape: const StadiumBorder(),
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 3,
        highlightElevation: 6,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLowest,
    );
  }

  ThemeData _blackTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme = dynamicColorScheme?.copyWith(
          surface: Colors.black,
          surfaceTint: Colors.transparent,
          surfaceContainer: const Color(0xFF121212),
          surfaceContainerHigh: const Color(0xFF1E1E1E),
          surfaceContainerHighest: const Color(0xFF2C2C2C),
          surfaceContainerLow: const Color(0xFF0A0A0A),
          surfaceContainerLowest: Colors.black,
        ) ??
        const ColorScheme.dark(
          primary: Colors.white,
          onSurface: Colors.white,
          secondary: Colors.grey,
          surface: Colors.black,
          onPrimary: Colors.black,
          primaryContainer: Color(0xFF1F1F1F),
          surfaceTint: Colors.transparent,
          surfaceContainer: Color(0xFF121212),
          surfaceContainerHigh: Color(0xFF1E1E1E),
          surfaceContainerHighest: Color(0xFF2C2C2C),
          surfaceContainerLow: Color(0xFF0A0A0A),
          surfaceContainerLowest: Colors.black,
        );

    final baseTheme = ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      cardColor: Colors.black,
      dialogBackgroundColor: const Color(0xFF1E1E22),
      primaryColor:
          dynamicColorScheme == null ? Colors.black : colorScheme.primary,
      hintColor: dynamicColorScheme == null
          ? Colors.black
          : colorScheme.onSurfaceVariant,
      primaryColorDark: Colors.black,
      primaryColorLight: Colors.black,
    );

    return _applyM3ExpressiveTheme(baseTheme, colorScheme).copyWith(
      scaffoldBackgroundColor: Colors.black,
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E22),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1E1E22),
        modalBackgroundColor: const Color(0xFF1E1E22),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
      ),
    );
  }

  ThemeMode get theme {
    switch (themeText.value) {
      case "light":
        return ThemeMode.light;
      case "dark":
        return ThemeMode.dark;
      case "black":
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  changeTheme(String mode) {
    MiruStorage.setSetting(SettingKey.theme, mode);
    themeText.value = mode;
    Get.forceAppUpdate();
  }

  changeMaterialYouColors(bool enabled) {
    MiruStorage.setSetting(SettingKey.materialYouColors, enabled);
    materialYouColors.value = enabled;
    Get.forceAppUpdate();
  }

  NavigationDestinationLabelBehavior get navigationLabelBehavior {
    switch (androidNavigationLabels.value) {
      case 'all':
        return NavigationDestinationLabelBehavior.alwaysShow;
      case 'none':
        return NavigationDestinationLabelBehavior.alwaysHide;
      default:
        return NavigationDestinationLabelBehavior.onlyShowSelected;
    }
  }

  changeAndroidNavigationLabels(String value) {
    MiruStorage.setSetting(SettingKey.androidNavigationLabels, value);
    androidNavigationLabels.value = value;
  }
}
