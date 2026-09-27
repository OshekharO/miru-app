import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miru_app/controllers/application_controller.dart';
import 'package:miru_app/utils/android_system_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android Material You themes', () {
    final lightDynamic = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006E1C),
    );
    final darkDynamic = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006E1C),
      brightness: Brightness.dark,
    );

    test('uses wallpaper schemes only when the persisted toggle is enabled',
        () {
      final controller = ApplicationController();

      final standardTheme = controller.mobileLightTheme(
        lightDynamic,
        darkDynamic,
      );
      expect(standardTheme.colorScheme.primary, isNot(lightDynamic.primary));

      controller.materialYouColors.value = true;
      final lightTheme = controller.mobileLightTheme(
        lightDynamic,
        darkDynamic,
      );
      final darkTheme = controller.mobileDarkTheme(darkDynamic);

      expect(lightTheme.colorScheme.primary, lightDynamic.primary);
      expect(lightTheme.colorScheme.surface, lightDynamic.surface);
      expect(darkTheme.colorScheme.primary, darkDynamic.primary);
      expect(darkTheme.colorScheme.surface, darkDynamic.surface);
    });

    test('keeps AMOLED surfaces black while using wallpaper accents', () {
      final controller = ApplicationController()
        ..themeText.value = 'black'
        ..materialYouColors.value = true;

      final theme = controller.mobileLightTheme(lightDynamic, darkDynamic);

      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.colorScheme.surface, Colors.black);
      expect(theme.colorScheme.primary, darkDynamic.primary);
    });
  });

  test('maps the Android bottom navigation label preference', () {
    final controller = ApplicationController();

    expect(
      controller.navigationLabelBehavior,
      NavigationDestinationLabelBehavior.onlyShowSelected,
    );

    controller.androidNavigationLabels.value = 'all';
    expect(
      controller.navigationLabelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );

    controller.androidNavigationLabels.value = 'none';
    expect(
      controller.navigationLabelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
  });

  testWidgets('Android system navigation bar is transparent', (tester) async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await configureAndroidSystemUi();
    await tester.pump();

    expect(
      calls.where(
        (call) =>
            call.method == 'SystemChrome.setEnabledSystemUIMode' &&
            call.arguments == 'SystemUiMode.edgeToEdge',
      ),
      isNotEmpty,
    );

    final style = SystemChrome.latestStyle!;
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.systemNavigationBarDividerColor, Colors.transparent);
    expect(style.systemNavigationBarContrastEnforced, isFalse);
  });
}
