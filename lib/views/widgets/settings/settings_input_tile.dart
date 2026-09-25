import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';

class SettingsIntpuTile extends fluent.StatefulWidget {
  const SettingsIntpuTile({
    super.key,
    this.icon,
    this.iconBgColor,
    required this.title,
    required this.onChanged,
    required this.buildText,
    required this.buildSubtitle,
    this.trailing = const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    this.isCard = false,
  });

  final Widget? icon;
  final Color? iconBgColor;
  final String title;
  final String Function() buildSubtitle;
  final String Function() buildText;
  final Widget trailing;
  final Function(String) onChanged;
  final bool isCard;

  @override
  fluent.State<SettingsIntpuTile> createState() => _SettingsIntpuTileState();
}

class _SettingsIntpuTileState extends fluent.State<SettingsIntpuTile> {
  TextEditingController? _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.buildText());
  }

  @override
  void didUpdateWidget(covariant SettingsIntpuTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentText = widget.buildText();
    if (_controller != null &&
        _controller!.text != currentText &&
        _debounceTimer?.isActive != true) {
      _controller!.text = currentText;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  Widget _buildAndroid(BuildContext context) {
    return SettingsTile(
      isCard: widget.isCard,
      icon: widget.icon,
      iconBgColor: widget.iconBgColor,
      title: widget.title,
      buildSubtitle: widget.buildSubtitle,
      trailing: widget.trailing,
      onTap: () {
        final textController = TextEditingController(text: widget.buildText());
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(widget.title),
              content: TextField(
                controller: textController,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('common.cancel'.i18n),
                ),
                TextButton(
                  onPressed: () {
                    final newValue = textController.text;
                    widget.onChanged(newValue);
                    if (mounted) {
                      setState(() {
                        _controller?.text = newValue;
                      });
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: Text('common.confirm'.i18n),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return SettingsTile(
      isCard: widget.isCard,
      icon: widget.icon,
      iconBgColor: widget.iconBgColor,
      title: widget.title,
      buildSubtitle: widget.buildSubtitle,
      trailing: Expanded(
        child: fluent.TextBox(
          controller: _controller,
          onChanged: _onTextChanged,
        ),
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
