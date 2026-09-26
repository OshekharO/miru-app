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
    if (colorScheme != null) {
      return ThemeData(useMaterial3: true, colorScheme: colorScheme);
    }
    return brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
  }

  ThemeData _blackTheme(ColorScheme? dynamicColorScheme) {
    final colorScheme = dynamicColorScheme?.copyWith(
          surface: Colors.black,
          background: Colors.black,
          surfaceTint: Colors.transparent,
        ) ??
        const ColorScheme.dark(
          primary: Colors.white,
          onBackground: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          secondary: Colors.grey,
          surface: Colors.black,
          background: Colors.black,
          onPrimary: Colors.black,
          primaryContainer: Color(0xFF1F1F1F),
          surfaceTint: Colors.transparent,
        );

    return ThemeData.dark(useMaterial3: true).copyWith(
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
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E1E22),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1E1E22),
        modalBackgroundColor: const Color(0xFF1E1E22),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
        ),
      ),
      colorScheme: colorScheme,
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
