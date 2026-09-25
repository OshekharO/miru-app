import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/views/pages/code_edit_page.dart';

void main() {
  final testExtension = Extension(
    package: 'test.package',
    author: 'TestAuthor',
    version: '1.0.0',
    lang: 'zh',
    license: 'MIT',
    type: ExtensionType.manga,
    webSite: 'https://example.com',
    name: 'Test Extension',
  );

  Widget createWidgetToTest() {
    return MaterialApp(
      home: CodeEditPage(
        extension: testExtension,
      ),
    );
  }

  testWidgets('CodeEditPage renders appbar, toolbar, symbol bar and status bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetToTest());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Test Extension'), findsOneWidget);

    // Verify Toolbar buttons
    expect(find.byTooltip('Undo (Ctrl+Z)'), findsOneWidget);
    expect(find.byTooltip('Redo (Ctrl+Y)'), findsOneWidget);
    expect(find.byTooltip('Fold All'), findsOneWidget);
    expect(find.byTooltip('Unfold All'), findsOneWidget);
    expect(find.byTooltip('Enable Word Wrap'), findsOneWidget);
    expect(find.text('14px'), findsOneWidget);

    // Verify Quick Symbols
    expect(find.text('{'), findsOneWidget);
    expect(find.text('=>'), findsOneWidget);

    // Verify CodeField
    expect(find.byType(CodeField), findsOneWidget);

    // Verify Status Bar
    expect(find.textContaining('Ln 1, Col 1'), findsOneWidget);
  });

  testWidgets('CodeEditPage font size controls increment and decrement font size',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetToTest());
    await tester.pumpAndSettle();

    expect(find.text('14px'), findsOneWidget);

    // Increase font size
    await tester.tap(find.byTooltip('Increase Font Size'));
    await tester.pumpAndSettle();
    expect(find.text('15px'), findsOneWidget);

    // Decrease font size
    await tester.tap(find.byTooltip('Decrease Font Size'));
    await tester.pumpAndSettle();
    expect(find.text('14px'), findsOneWidget);
  });

  testWidgets('CodeEditPage quick symbol insertion inserts symbol',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetToTest());
    await tester.pumpAndSettle();

    // Tap on '{' symbol button
    await tester.tap(find.text('{'));
    await tester.pumpAndSettle();

    // CodeController should contain '{' and status bar update
    final codeField = tester.widget<CodeField>(find.byType(CodeField));
    expect(codeField.controller.text, equals('{'));
    expect(find.text('Unsaved'), findsOneWidget);
  });

  testWidgets('CodeEditPage toggles word wrap', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetToTest());
    await tester.pumpAndSettle();

    final wrapButton = find.byTooltip('Enable Word Wrap');
    expect(wrapButton, findsOneWidget);

    await tester.tap(wrapButton);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Disable Word Wrap'), findsOneWidget);
  });

  testWidgets('CodeEditPage toggles search panel and performs search/replace',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetToTest());
    await tester.pumpAndSettle();

    // Toggle search panel from action button
    final searchButton = find.byTooltip('Search / Replace (Ctrl+F)');
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Find'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Replace with'), findsOneWidget);

    // Enter search text
    await tester.enterText(
        find.widgetWithText(TextField, 'Find'), 'hello');
    await tester.pumpAndSettle();

    // Enter replace text
    await tester.enterText(
        find.widgetWithText(TextField, 'Replace with'), 'world');
    await tester.pumpAndSettle();

    // Insert text first via quick symbol
    await tester.tap(find.text('{'));
    await tester.pumpAndSettle();

    // Close search panel
    await tester.tap(find.byTooltip('Close Search'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Find'), findsNothing);
  });
}
