import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:get/get.dart';
import 'package:miru_app/models/extension_setting.dart';
import 'package:miru_app/views/pages/code_edit_page.dart';
import 'package:miru_app/controllers/extension/extension_settings_controller.dart';
import 'package:miru_app/views/widgets/extension/info_card.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/data/services/database_service.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/layout.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';
import 'package:miru_app/views/widgets/card_tile.dart';
import 'package:miru_app/views/widgets/messenger.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/progress.dart';
import 'package:miru_app/views/widgets/settings/settings_input_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_switch_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';

class ExtensionSettingsPage extends StatefulWidget {
  const ExtensionSettingsPage({
    super.key,
    required this.package,
  });
  final String package;

  @override
  State<ExtensionSettingsPage> createState() => _ExtensionSettingsPageState();
}

class _ExtensionSettingsPageState extends State<ExtensionSettingsPage> {
  late ExtensionSettingsPageController c;

  @override
  void initState() {
    c = Get.put(
      ExtensionSettingsPageController(widget.package),
      tag: widget.package,
    );
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<ExtensionSettingsPageController>(tag: widget.package);
    super.dispose();
  }

  Widget _buildSettingsList() {
    return Obx(() {
      final list = <Widget>[];

      for (final setting in c.settings) {
        if (setting.type == ExtensionSettingType.input) {
          list.add(SettingsIntpuTile(
            isCard: true,
            title: setting.title,
            onChanged: (value) async {
              setting.value = value;
              await DatabaseService.putExtensionSetting(
                setting.package,
                setting.key,
                value,
              );
              c.settings.refresh();
            },
            buildText: () {
              return setting.value ?? setting.defaultValue;
            },
            buildSubtitle: () {
              if (Platform.isAndroid) {
                return '${setting.value ?? setting.defaultValue}\n${setting.description ?? ''}';
              }
              return setting.description ?? '';
            },
          ));
        } else if (setting.type == ExtensionSettingType.radio) {
          Map<String, String> map = {};
          if (setting.options != null && setting.options!.isNotEmpty) {
            try {
              map = Map<String, String>.from(jsonDecode(setting.options!));
            } catch (_) {}
          }
          list.add(SettingsRadiosTile(
            isCard: true,
            title: setting.title,
            itemNameValue: map,
            buildSubtitle: () => setting.description ?? '',
            applyValue: (value) async {
              setting.value = value.toString();
              await DatabaseService.putExtensionSetting(
                setting.package,
                setting.key,
                value.toString(),
              );
              c.settings.refresh();
            },
            buildGroupValue: () => setting.value ?? setting.defaultValue,
          ));
        } else if (setting.type == ExtensionSettingType.toggle) {
          list.add(SettingsSwitchTile(
            isCard: true,
            title: setting.title,
            onChanged: (value) async {
              setting.value = value.toString();
              await DatabaseService.putExtensionSetting(
                setting.package,
                setting.key,
                value.toString(),
              );
              c.settings.refresh();
            },
            buildSubtitle: () => setting.description ?? '',
            buildValue: () {
              return (setting.value ?? setting.defaultValue).toLowerCase() ==
                  'true';
            },
          ));
        }
        list.add(const SizedBox(height: 8));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      );
    });
  }

  Widget _buildAndroid(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('extension-info.title'.i18n),
      ),
      body: Obx(() {
        if (c.runtime.value == null) {
          return const Center(
            child: ProgressRing(),
          );
        }
        final extension = c.runtime.value!.extension;

        Widget headerAndInfo = Column(
          children: [
            // Header Card
            Center(
              child: Column(
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CacheNetWorkImagePic(
                      extension.icon ?? '',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    extension.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    extension.package,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? theme.colorScheme.primary.withOpacity(0.4)
                            : theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ExtensionUtils.typeToString(extension.type),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metadata Grid Section
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    icon: Icons.person_outline,
                    title: 'extension-info.author'.i18n,
                    content: extension.author,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InfoCard(
                    icon: Icons.info_outline,
                    title: 'extension-info.version'.i18n,
                    content: extension.version,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    icon: Icons.language_outlined,
                    title: 'extension-info.language'.i18n,
                    content: extension.lang,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InfoCard(
                    icon: Icons.article_outlined,
                    title: 'extension-info.license'.i18n,
                    content: extension.license,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoCard(
              icon: Icons.link,
              title: 'extension-info.original-site'.i18n,
              content: extension.webSite,
              fullWidth: true,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text('common.uninstall'.i18n),
                    onPressed: () async {
                      await ExtensionUtils.uninstall(extension.package);
                      Get.back();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.code, size: 18),
                    label: Text('extension.edit-code'.i18n),
                    onPressed: () {
                      Get.to(CodeEditPage(extension: extension));
                    },
                  ),
                ),
              ],
            ),
          ],
        );

        Widget settingsSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.settings'.i18n,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SettingsTile(
              isCard: true,
              icon: const Icon(Icons.cleaning_services_outlined, size: 20),
              title: 'cookie-clean.title'.i18n,
              buildSubtitle: () => 'cookie-clean.subtitle'.i18n,
              trailing: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('cookie-clean.clean'.i18n),
                onPressed: () {
                  c.runtime.value!.cleanCookie();
                  showPlatformSnackbar(
                    context: context,
                    content: 'cookie-clean.success'.i18n,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildSettingsList(),
          ],
        );

        if (LayoutUtils.isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: headerAndInfo,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: settingsSection,
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              headerAndInfo,
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              settingsSection,
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Obx(() {
      if (c.runtime.value == null) {
        return const Center(
          child: ProgressRing(),
        );
      }

      final extension = c.runtime.value!.extension;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: LayoutBuilder(builder: ((context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (constraints.maxWidth > 800)
                SizedBox(
                  width: 320,
                  child: fluent.Card(
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CacheNetWorkImagePic(
                            extension.icon ?? '',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          extension.name,
                          style: fluent.FluentTheme.of(context)
                              .typography
                              .bodyLarge,
                        ),
                        Text(
                          extension.package,
                          style: fluent.FluentTheme.of(context).typography.body,
                        ),
                        const SizedBox(height: 16),
                        fluent.FilledButton(
                          onPressed: () async {
                            await ExtensionUtils.uninstall(extension.package);
                            router.pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            child: Text('common.uninstall'.i18n),
                          ),
                        ),
                        const SizedBox(height: 50),
                        fluent.Card(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          child: Text(
                            ExtensionUtils.typeToString(extension.type),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (extension.description != null) ...[
                        CardTile(
                          title: 'extension-info.description'.i18n,
                          child: SelectableText(
                            extension.description!,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CardTile(
                        title: 'extension-info.other-information'.i18n,
                        child: Wrap(
                          children: [
                            InfoCard(
                              icon: fluent.FluentIcons.contact,
                              title: 'extension-info.author'.i18n,
                              content: extension.author,
                            ),
                            InfoCard(
                              icon: fluent.FluentIcons.code,
                              title: 'extension-info.version'.i18n,
                              content: extension.version,
                            ),
                            InfoCard(
                              icon: fluent.FluentIcons.locale_language,
                              title: 'extension-info.language'.i18n,
                              content: extension.lang,
                            ),
                            InfoCard(
                              icon: fluent.FluentIcons.page,
                              title: 'extension-info.license'.i18n,
                              content: extension.license,
                            ),
                            InfoCard(
                              icon: fluent.FluentIcons.globe,
                              title: 'extension-info.original-site'.i18n,
                              content: extension.webSite,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'common.settings'.i18n,
                        style: fluent.FluentTheme.of(context)
                            .typography
                            .subtitle,
                      ),
                      const SizedBox(height: 16),
                      SettingsTile(
                        isCard: true,
                        title: 'cookie-clean.title'.i18n,
                        buildSubtitle: () => 'cookie-clean.subtitle'.i18n,
                        trailing: fluent.FilledButton(
                          child: Text('cookie-clean.clean'.i18n),
                          onPressed: () {
                            c.runtime.value!.cleanCookie();
                            showPlatformSnackbar(
                              context: context,
                              content: 'cookie-clean.success'.i18n,
                              severity: fluent.InfoBarSeverity.success,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsList(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              )
            ],
          );
        })),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuildWidget(
      androidBuilder: _buildAndroid,
      desktopBuilder: _buildDesktop,
    );
  }
}
