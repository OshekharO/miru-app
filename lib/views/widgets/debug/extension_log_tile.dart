import 'package:flutter/material.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';

class ExtensionLogTile extends StatelessWidget {
  const ExtensionLogTile({super.key, required this.log});
  final ExtensionLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = log.level == ExtensionLogLevel.error;
    final timeStr =
        '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}';

        final badgeContainerColor = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.primaryContainer;
    final badgeTextColor = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isError
          ? theme.colorScheme.errorContainer.withOpacity(0.25)
          : theme.colorScheme.surfaceContainerBorder,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isError
              ? theme.colorScheme.error.withOpacity(0.4)
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.extension.icon != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CacheNetWorkImagePic(
                  log.extension.icon!,
                  width: 32,
                  height: 32,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.extension.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeContainerColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isError ? 'ERROR' : 'INFO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    log.content,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isError ? theme.colorScheme.error : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on ColorScheme {
  Color get surfaceContainerBorder => surfaceContainerHighest;
}
