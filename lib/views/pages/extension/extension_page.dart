import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/extension/extension_controller.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/views/widgets/extension/extension_tile.dart';
import 'package:miru_app/views/pages/extension/extension_repo_page.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/router.dart';
import 'package:miru_app/views/widgets/button.dart';
import 'package:miru_app/views/widgets/messenger.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ExtensionPage extends StatefulWidget {
  const ExtensionPage({super.key});

  @override
  State<ExtensionPage> createState() => _ExtensionPageState();
}

class _ExtensionPageState extends State<ExtensionPage> {
  late ExtensionPageController c;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    c = Get.put(ExtensionPageController());
    c.isPageOpen = true;
    if (c.needRefresh) {
      c.onRefresh();
    }
    super.initState();
  }

  @override
  void dispose() {
    c.isPageOpen = false;
    _searchController.dispose();
    super.dispose();
  }

  // 导入扩展对话框
  _importDialog() {
    String url = '';
    showPlatformDialog(
      context: context,
      title: 'extension.import.title'.i18n,
      maxWidth: 500,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlatformWidget(
            androidWidget: TextField(
              decoration: InputDecoration(
                labelText: 'extension.import.url-label'.i18n,
                hintText: "https://example.com/extension.js",
              ),
              onChanged: (value) {
                url = value;
              },
            ),
            desktopWidget: Row(
              children: [
                Expanded(
                    child: fluent.TextBox(
                  placeholder: 'extension.import.url-label'.i18n,
                  onChanged: (value) {
                    url = value;
                  },
                )),
                const SizedBox(width: 8),
                fluent.Tooltip(
                  message: 'extension.import.extension-dir'.i18n,
                  child: fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.fabric_folder),
                    onPressed: () async {
                      RouterUtils.pop();
                      final dir = ExtensionUtils.extensionsDir;
                      final uri = Uri.directory(dir);
                      await launchUrl(uri);
                    },
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(fluent.FluentIcons.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "extension.import.tips".i18n,
                  softWrap: true,
                ),
              )
            ],
          ),
        ],
      ),
      actions: [
        PlatformButton(
          onPressed: () {
            RouterUtils.pop();
          },
          child: Text('common.cancel'.i18n),
        ),
        PlatformFilledButton(
          onPressed: () async {
            RouterUtils.pop();
            await ExtensionUtils.install(url, context);
          },
          child: Text('extension.import.import-by-url'.i18n),
        ),
        PlatformFilledButton(
          child: Text('extension.import.import-by-local'.i18n),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['js'],
            );
            if (result == null || !mounted) {
              return;
            }
            final path = result.files.single.path;
            if (path == null) {
              return;
            }
            final script = await File(path).readAsString();
            await ExtensionUtils.installByScript(script, context);
            RouterUtils.pop();
          },
        ),
      ],
    );
  }

  // 加载错误对话框
  _loadErrorDialog() {
    showPlatformDialog(
      context: context,
      title: 'extension.error-dialog'.i18n,
      maxWidth: 540,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in c.errors.entries)
              PlatformWidget(
                androidWidget: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                path.basename(e.key),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: e.value),
                                );
                                showPlatformSnackbar(
                                  context: context,
                                  content: 'common.copy-success'.i18n,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          e.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                desktopWidget: fluent.Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            fluent.FluentIcons.warning,
                            color: fluent.Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              path.basename(e.key),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          fluent.IconButton(
                            icon: const Icon(fluent.FluentIcons.copy, size: 14),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: e.value),
                              );
                              showPlatformSnackbar(
                                context: context,
                                content: 'common.copy-success'.i18n,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: fluent.FluentTheme.of(context)
                              .typography
                              .body
                              ?.color
                              ?.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        PlatformButton(
          onPressed: () {
            RouterUtils.pop();
          },
          child: Text('common.confirm'.i18n),
        ),
      ],
    );
  }

  List get _filteredExtensions {
    return c.runtimes.values.where((ext) {
      final matchesSearch = c.search.value.isEmpty ||
          ext.extension.name
              .toLowerCase()
              .contains(c.search.value.toLowerCase()) ||
          ext.extension.package
              .toLowerCase()
              .contains(c.search.value.toLowerCase());
      final matchesType = c.filterType.value == null ||
          ext.extension.type == c.filterType.value;
      return matchesSearch && matchesType;
    }).toList();
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      {'type': null, 'label': 'common.show-all'.i18n, 'icon': Icons.apps},
      {
        'type': ExtensionType.bangumi,
        'label': 'extension-type.video'.i18n,
        'icon': Icons.movie_outlined
      },
      {
        'type': ExtensionType.manga,
        'label': 'extension-type.comic'.i18n,
        'icon': Icons.menu_book_outlined
      },
      {
        'type': ExtensionType.fikushon,
        'label': 'extension-type.novel'.i18n,
        'icon': Icons.book_outlined
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = c.filterType.value == cat['type'];
          final type = cat['type'] as ExtensionType?;
          final label = cat['label'] as String;
          final iconData = cat['icon'] as IconData;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              avatar: Icon(
                iconData,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(label),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor:
                  theme.colorScheme.surfaceVariant.withOpacity(0.5),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) {
                c.filterType.value = type;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isDesktop}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension_off_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            c.runtimes.isEmpty
                ? 'common.no-extension'.i18n
                : 'common.no-result'.i18n,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            fluent.FilledButton(
              child: Text('common.extension-repo'.i18n),
              onPressed: () {
                router.push('/extension_repo');
              },
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text('common.extension-repo'.i18n),
              onPressed: () {
                Get.to(() => const ExtensionRepoPage());
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'common.search'.i18n,
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  c.search.value = val;
                },
              )
            : Text('common.extension'.i18n),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                c.search.value = '';
                setState(() {
                  _isSearching = false;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          Obx(
            () => c.errors.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange),
                    onPressed: () => _loadErrorDialog(),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            onPressed: () => _importDialog(),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              Get.to(() => const ExtensionRepoPage());
            },
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: Obx(() {
        final list = _filteredExtensions;

        return Column(
          children: [
            if (c.runtimes.isNotEmpty) _buildFilterChips(context),
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyState(context, isDesktop: false)
                  : ListView.builder(
                      itemCount: list.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        return ExtensionTile(list[index].extension);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Controls
          Row(
            children: [
              Text(
                'common.extension'.i18n,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              // Search Bar
              SizedBox(
                width: 220,
                child: fluent.TextBox(
                  controller: _searchController,
                  placeholder: 'common.search'.i18n,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(fluent.FluentIcons.search, size: 14),
                  ),
                  onChanged: (val) {
                    c.search.value = val;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Filter Category Dropdown
              Obx(
                () => fluent.ComboBox<String>(
                  items: [
                    fluent.ComboBoxItem(
                      value: "all",
                      child: Text('common.show-all'.i18n),
                    ),
                    fluent.ComboBoxItem(
                      value: ExtensionType.bangumi.toString(),
                      child: Text('extension-type.video'.i18n),
                    ),
                    fluent.ComboBoxItem(
                      value: ExtensionType.manga.toString(),
                      child: Text('extension-type.comic'.i18n),
                    ),
                    fluent.ComboBoxItem(
                      value: ExtensionType.fikushon.toString(),
                      child: Text('extension-type.novel'.i18n),
                    ),
                  ],
                  value: c.filterType.value?.toString() ?? "all",
                  onChanged: (value) {
                    if (value == "all" || value == null) {
                      c.filterType.value = null;
                      return;
                    }
                    c.filterType.value = ExtensionType.values.firstWhere(
                      (element) => element.toString() == value,
                    );
                  },
                ),
              ),
              const Spacer(),
              // Error button
              Obx(
                () => c.errors.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          fluent.Tooltip(
                            message: 'extension.error-dialog'.i18n,
                            child: fluent.IconButton(
                              icon: Icon(fluent.FluentIcons.warning,
                                  color: fluent.Colors.orange),
                              onPressed: () {
                                _loadErrorDialog();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              // Import button
              fluent.Tooltip(
                message: 'extension.import.title'.i18n,
                child: fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.add_space_before),
                  onPressed: () {
                    _importDialog();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Extension Repo Button
              fluent.FilledButton(
                child: Row(
                  children: [
                    const Icon(fluent.FluentIcons.shopping_cart, size: 14),
                    const SizedBox(width: 6),
                    Text('common.extension-repo'.i18n),
                  ],
                ),
                onPressed: () {
                  router.push('/extension_repo');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: Obx(() {
              final list = _filteredExtensions;

              return list.isEmpty
                  ? _buildEmptyState(context, isDesktop: true)
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExtensionTile(list[index].extension),
                        );
                      },
                    );
            }),
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
