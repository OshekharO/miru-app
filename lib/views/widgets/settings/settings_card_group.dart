import 'package:flutter/material.dart';

class SettingsCardGroup extends StatelessWidget {
  const SettingsCardGroup({
    super.key,
    required this.children,
    this.title,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final String? title;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final validChildren = children.where((w) => w is! SizedBox || (w.height != 0 && w.width != 0)).toList();
    if (validChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark
        ? (theme.cardColor != Colors.black
            ? theme.cardColor
            : const Color(0xFF1E1C1E))
        : theme.cardColor;

    final dividerColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);

    final List<Widget> dividedChildren = [];
    for (int i = 0; i < validChildren.length; i++) {
      dividedChildren.add(validChildren[i]);
      if (i < validChildren.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 56,
            endIndent: 16,
            color: dividerColor,
          ),
        );
      }
    }

    final cardContent = Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: dividedChildren,
      ),
    );

    if (title != null && title!.isNotEmpty) {
      return Padding(
        padding: margin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            cardContent,
          ],
        ),
      );
    }

    return Padding(
      padding: margin,
      child: cardContent,
    );
  }
}
