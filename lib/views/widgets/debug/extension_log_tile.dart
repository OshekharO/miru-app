import 'package:fluent_ui/fluent_ui.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';

class ExtensionLogTile extends StatelessWidget {
  const ExtensionLogTile({super.key, required this.log});
  final ExtensionLog log;

  @override
  Widget build(BuildContext context) {
    final isError = log.level == ExtensionLogLevel.error;
    final timeStr =
        '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.withOpacity(0.12) : Colors.grey[160],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isError
              ? Colors.red.withOpacity(0.4)
              : Colors.grey[140]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.extension.icon != null) ...[
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: CacheNetWorkImagePic(
                log.extension.icon!,
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.extension.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isError
                            ? Colors.red.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isError ? 'ERROR' : 'INFO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isError ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: FluentTheme.of(context)
                            .typography
                            .caption
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  log.content,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isError ? Colors.red.light : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
