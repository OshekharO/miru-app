import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';

class SettingsTile extends StatefulWidget {
  const SettingsTile({
    super.key,
    this.icon,
    this.iconBgColor,
    required this.title,
    this.trailing,
    this.buildSubtitle,
    this.onTap,
    this.isCard = false,
  });

  final Widget? icon;
  final Color? iconBgColor;
  final String title;
  final String Function()? buildSubtitle;
  final Function()? onTap;
  final Widget? trailing;
  final bool isCard;

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  Widget _buildLeadingIcon() {
    if (widget.icon == null) return const SizedBox.shrink();

    if (widget.iconBgColor != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: IconTheme(
          data: const IconThemeData(color: Colors.white, size: 20),
          child: widget.icon!,
        ),
      );
    }

    return widget.icon!;
  }

  Widget _buildAndroid(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasSubtitle = widget.buildSubtitle != null;
    final subtitleText = hasSubtitle ? widget.buildSubtitle!.call() : null;

    final effectiveTrailing = widget.trailing ??
        (widget.onTap != null
            ? Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[400],
                size: 20,
              )
            : null);

    Widget tileContent = InkWell(
      borderRadius: widget.isCard ? BorderRadius.circular(12) : null,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (widget.icon != null) ...[
              _buildLeadingIcon(),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitleText != null && subtitleText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (effectiveTrailing != null) ...[
              const SizedBox(width: 8),
              effectiveTrailing,
            ],
          ],
        ),
      ),
    );

    if (widget.isCard) {
      final isBlack = isDark && theme.scaffoldBackgroundColor == Colors.black;

      final cardBgColor = isBlack
          ? Colors.black
          : isDark
              ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3);

      final borderColor = isBlack
          ? Colors.white.withOpacity(0.12)
          : theme.colorScheme.outline.withOpacity(0.15);

      return Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: tileContent,
      );
    }

    return tileContent;
  }

  Widget _buildDesktop(BuildContext context) {
    final effectiveTrailing = widget.trailing ??
        (widget.onTap != null
            ? const Icon(
                fluent.FluentIcons.chevron_right,
                size: 14,
              )
            : const SizedBox());

    Widget content = Row(
      children: [
        if (widget.icon != null) ...[
          _buildLeadingIcon(),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (widget.buildSubtitle != null)
                Text(
                  widget.buildSubtitle!.call(),
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                )
            ],
          ),
        ),
        const SizedBox(width: 12),
        effectiveTrailing,
      ],
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    if (widget.isCard) {
      return fluent.Card(
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: content,
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
