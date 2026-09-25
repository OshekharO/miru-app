import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/progress.dart';

class ExtensionCard extends StatefulWidget {
  const ExtensionCard({
    super.key,
    required this.name,
    required this.version,
    required this.icon,
    required this.package,
    required this.lang,
    required this.nsfw,
    required this.type,
  });
  final String? icon;
  final String name;
  final String version;
  final String package;
  final String lang;
  final ExtensionType type;
  final bool nsfw;

  @override
  State<ExtensionCard> createState() => _ExtensionCardState();
}

class _ExtensionCardState extends State<ExtensionCard> {
  bool isLoading = false;
  bool isInstall = false;
  bool hasUpgrade = false;
  late String icon = widget.icon ?? '';

  @override
  void initState() {
    super.initState();
    isInstall = ExtensionUtils.runtimes.containsKey(widget.package);
    hasUpgrade = isInstall &&
        ExtensionUtils.runtimes[widget.package]!.extension.version !=
            widget.version;
  }

  _install() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = MiruStorage.getSetting(SettingKey.miruRepoUrl) +
          "/repo/${widget.package}.js";
      debugPrint(url);
      await ExtensionUtils.install(url, context);
      isLoading = false;
      isInstall = true;
      hasUpgrade = false;
    } catch (e) {
      debugPrint(e.toString());
      isLoading = false;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildTypeBadge(BuildContext context, ExtensionType type) {
    Color color;
    IconData iconData;
    switch (type) {
      case ExtensionType.bangumi:
        color = Colors.blue;
        iconData = Icons.movie_outlined;
        break;
      case ExtensionType.manga:
        color = Colors.orange;
        iconData = Icons.menu_book_outlined;
        break;
      case ExtensionType.fikushon:
        color = Colors.purple;
        iconData = Icons.book_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            ExtensionUtils.typeToString(type),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              ),
              clipBehavior: Clip.antiAlias,
              child: CacheNetWorkImagePic(
                icon,
                fit: BoxFit.contain,
                fallback: const Icon(Icons.extension_outlined, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            // Information Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTypeBadge(context, widget.type),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.version,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                      if (widget.lang.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.lang,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      if (widget.nsfw)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '18+',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: ProgressRing(),
              )
            else if (isInstall) ...[
              if (hasUpgrade)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    await _install();
                  },
                  child: Text('extension-repo.upgrade'.i18n),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    await ExtensionUtils.uninstall(widget.package);
                    setState(() {
                      isInstall = false;
                    });
                  },
                  child: Text('common.uninstall'.i18n),
                ),
            ] else
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () async {
                  await _install();
                },
                child: Text('common.install'.i18n),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return fluent.Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: fluent.FluentTheme.of(context)
                      .resources
                      .subtleFillColorSecondary,
                ),
                clipBehavior: Clip.antiAlias,
                child: CacheNetWorkImagePic(
                  icon,
                  fit: BoxFit.contain,
                  fallback: const Icon(fluent.FluentIcons.add_in, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildTypeBadge(context, widget.type),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'v${widget.version}',
                style: TextStyle(
                  fontSize: 12,
                  color: fluent.FluentTheme.of(context).inactiveColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${widget.lang})',
                style: TextStyle(
                  fontSize: 12,
                  color: fluent.FluentTheme.of(context).inactiveColor,
                ),
              ),
              if (widget.nsfw) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '18+',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: ProgressRing(),
                )
              else if (isInstall) ...[
                if (hasUpgrade)
                  fluent.FilledButton(
                    onPressed: () async {
                      await _install();
                    },
                    child: Text('extension-repo.upgrade'.i18n),
                  )
                else
                  fluent.Button(
                    onPressed: () async {
                      await ExtensionUtils.uninstall(widget.package);
                      setState(() {
                        isInstall = false;
                      });
                    },
                    child: Text('common.uninstall'.i18n),
                  ),
              ] else
                fluent.FilledButton(
                  onPressed: () async {
                    await _install();
                  },
                  child: Text('common.install'.i18n),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuildWidget(
      androidBuilder: _buildAndroid,
      desktopBuilder: _buildDesktop,
    );
  }
}
