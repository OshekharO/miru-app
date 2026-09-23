import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/views/pages/code_edit_page.dart';
import 'package:miru_app/views/pages/extension/extension_settings_page.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

class ExtensionTile extends StatefulWidget {
  const ExtensionTile(this.extension, {super.key});
  final Extension extension;

  @override
  State<ExtensionTile> createState() => _ExtensionTileState();
}

class _ExtensionTileState extends State<ExtensionTile> {
  final fluent.FlyoutController moreFlyoutController =
      fluent.FlyoutController();

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: color),
          const SizedBox(width: 4),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.to(() => ExtensionSettingsPage(package: widget.extension.package));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                ),
                clipBehavior: Clip.antiAlias,
                child: CacheNetWorkImagePic(
                  widget.extension.icon ?? '',
                  key: ValueKey(widget.extension.icon),
                  fit: BoxFit.contain,
                  fallback: const Icon(Icons.extension_outlined, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.extension.name,
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
                        _buildTypeBadge(context, widget.extension.type),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.extension.version,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                        if (widget.extension.author.isNotEmpty)
                          Text(
                            widget.extension.author,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.extension.nsfw)
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
              // Actions
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                tooltip: 'settings.general'.i18n,
                onPressed: () {
                  Get.to(() => ExtensionSettingsPage(
                      package: widget.extension.package));
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            ListTile(
                              leading: const Icon(Icons.code),
                              title: Text('extension.edit-code'.i18n),
                              onTap: () async {
                                Get.back();
                                Get.to(() =>
                                    CodeEditPage(extension: widget.extension));
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              title: Text(
                                'common.uninstall'.i18n,
                                style: const TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                ExtensionUtils.uninstall(
                                    widget.extension.package);
                                Get.back();
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return fluent.Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: CacheNetWorkImagePic(
              widget.extension.icon ?? '',
              key: ValueKey(widget.extension.icon),
              fit: BoxFit.contain,
              fallback: const Icon(fluent.FluentIcons.add_in, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          // Name & Author
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.extension.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.extension.author.isNotEmpty
                      ? widget.extension.author
                      : widget.extension.package,
                  style: TextStyle(
                    fontSize: 12,
                    color: fluent.FluentTheme.of(context)
                        .typography
                        .caption
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Type badge
          _buildTypeBadge(context, widget.extension.type),
          const SizedBox(width: 16),
          // Version
          Text(
            widget.extension.version,
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          // Settings action button
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.settings, size: 16),
            onPressed: () {
              router.push(Uri(
                path: '/extension_settings',
                queryParameters: {'package': widget.extension.package},
              ).toString());
            },
          ),
          const SizedBox(width: 8),
          // More flyout action button
          fluent.FlyoutTarget(
            controller: moreFlyoutController,
            child: fluent.IconButton(
              icon: const Icon(fluent.FluentIcons.more, size: 16),
              onPressed: () {
                moreFlyoutController.showFlyout(
                  autoModeConfiguration: fluent.FlyoutAutoConfiguration(
                    preferredMode: fluent.FlyoutPlacementMode.bottomLeft,
                  ),
                  builder: (context) {
                    return fluent.MenuFlyout(
                      items: [
                        fluent.MenuFlyoutItem(
                          leading: const Icon(fluent.FluentIcons.code),
                          text: Text('extension.edit-code'.i18n),
                          onPressed: () async {
                            fluent.Flyout.of(context).close();
                            launchUrl(path.toUri(
                              '${ExtensionUtils.extensionsDir}/${widget.extension.package}.js',
                            ));
                          },
                        ),
                        fluent.MenuFlyoutItem(
                          leading: const Icon(fluent.FluentIcons.delete),
                          text: Text('common.uninstall'.i18n),
                          onPressed: () {
                            ExtensionUtils.uninstall(widget.extension.package);
                            fluent.Flyout.of(context).close();
                          },
                        ),
                      ],
                    );
                  },
                  barrierDismissible: true,
                  dismissWithEsc: true,
                );
              },
            ),
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
