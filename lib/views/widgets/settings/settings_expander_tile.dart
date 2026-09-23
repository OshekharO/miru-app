import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:get/get.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/settings/settings_card_group.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';

class SettingsExpanderTile extends StatelessWidget {
  const SettingsExpanderTile({
    super.key,
    this.icon,
    this.androidIcon,
    this.leading,
    this.iconBgColor,
    required this.content,
    required this.title,
    required this.subTitle,
    this.open = false,
    this.noPage = false,
  });

  final IconData? icon;
  final IconData? androidIcon;
  final Widget? leading;
  final Color? iconBgColor;
  final String title;
  final String subTitle;
  final bool open;
  final Widget content;
  // 不使用二级页面
  final bool noPage;

  Widget _buildSubPageBody(BuildContext context) {
    if (content is Column) {
      final col = content as Column;

      List<Widget> groupItems = [];
      List<Widget> cardGroups = [];

      for (final child in col.children) {
        if (child is SizedBox && (child.height ?? 0) >= 15) {
          if (groupItems.isNotEmpty) {
            cardGroups.add(SettingsCardGroup(children: List.from(groupItems)));
            groupItems.clear();
          }
        } else {
          groupItems.add(child);
        }
      }
      if (groupItems.isNotEmpty) {
        cardGroups.add(SettingsCardGroup(children: List.from(groupItems)));
      }

      return Column(
        children: cardGroups,
      );
    }

    return SettingsCardGroup(children: [content]);
  }

  Widget _buildAndroid(BuildContext context) {
    if (noPage) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return SettingsCardGroup(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              content,
            ],
          ),
        ],
      );
    }

    Widget iconWidget = androidIcon != null
        ? Icon(androidIcon, size: 20)
        : icon != null
            ? Icon(icon, size: 20)
            : leading!;

    return SettingsTile(
      icon: iconWidget,
      iconBgColor: iconBgColor,
      title: title,
      buildSubtitle: () => subTitle,
      onTap: () {
        Get.to(
          () => Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? null
                : const Color(0xFFEFF2F6),
            appBar: AppBar(
              title: Text(title),
              centerTitle: true,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildSubPageBody(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    Widget iconWidget = icon != null
        ? Icon(icon, size: 20)
        : leading ?? const SizedBox.shrink();

    if (iconBgColor != null && icon != null) {
      iconWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: IconTheme(
          data: const IconThemeData(color: Colors.white, size: 18),
          child: Icon(icon),
        ),
      );
    }

    return fluent.Expander(
      initiallyExpanded: open,
      leading: iconWidget,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            subTitle,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8)
        ],
      ),
      content: content,
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
