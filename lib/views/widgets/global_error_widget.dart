import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';

class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const GlobalErrorWidget({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      androidWidget: _buildAndroid(context),
      desktopWidget: _buildDesktop(context),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    final theme = Theme.of(context);
    final errorText = details.exceptionAsString();

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'An error occurred',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The application encountered an issue while rendering this component.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      errorText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: '$errorText\n\n${details.stack}'),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text('common.copy'.i18n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final fluentTheme = fluent.FluentTheme.of(context);
    final errorText = details.exceptionAsString();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: fluentTheme.resources.cardBackgroundFillColorDefault,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: fluent.Colors.red.normal.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fluent.FluentIcons.error_badge,
              size: 40,
              color: fluent.Colors.red.normal,
            ),
            const SizedBox(height: 12),
            Text(
              'An error occurred',
              style: fluentTheme.typography.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'The application encountered an issue while rendering this component.',
              style: fluentTheme.typography.body?.copyWith(
                color: fluentTheme.typography.body?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fluentTheme.resources.solidBackgroundFillColorBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: fluentTheme.resources.dividerStrokeColorDefault,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  errorText,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 12,
                    color: fluentTheme.typography.body?.color?.withOpacity(0.9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            fluent.Button(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: '$errorText\n\n${details.stack}'),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(fluent.FluentIcons.copy, size: 14),
                  const SizedBox(width: 6),
                  Text('common.copy'.i18n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
