import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/utils/miru_storage.dart';

class ApplicationController extends GetxController {
  static get find => Get.find();

  final themeText = "system".obs;

  @override
  void onInit() {
    themeText.value = MiruStorage.getSetting(SettingKey.theme);
    super.onInit();
  }

  ThemeData get currentThemeData {
    switch (themeText.value) {
      case "light":
        return ThemeData.light(useMaterial3: true);
      case "dark":
        return ThemeData.dark(useMaterial3: true);
      case "black":
        return ThemeData.dark(
          useMaterial3: true,
        ).copyWith(
          scaffoldBackgroundColor: Colors.black,
          canvasColor: const Color(0xFF161618),
          cardColor: const Color(0xFF161618),
          dialogBackgroundColor: const Color(0xFF1E1E22),
          primaryColor: Colors.black,
          hintColor: Colors.grey,
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
          colorScheme: ColorScheme.dark(
            primary: Colors.white,
            onBackground: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            secondary: Colors.grey,
            surface: const Color(0xFF161618),
            background: Colors.black,
            onPrimary: Colors.black,
            primaryContainer: const Color(0xFF26262A),
            surfaceTint: Colors.transparent,
          ),
        );
      default:
        return ThemeData.light(useMaterial3: true);
    }
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
}
