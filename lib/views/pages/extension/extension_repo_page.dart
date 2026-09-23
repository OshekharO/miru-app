import 'package:easy_refresh/easy_refresh.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/controllers/extension/extension_repo_controller.dart';
import 'package:miru_app/views/widgets/extension/extension_card.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/button.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/progress.dart';
import 'package:miru_app/views/widgets/search_appbar.dart';

class ExtensionRepoPage extends StatefulWidget {
  const ExtensionRepoPage({super.key});

  @override
  State<ExtensionRepoPage> createState() => _ExtensionRepoPageState();
}

class _ExtensionRepoPageState extends State<ExtensionRepoPage> {
  late ExtensionRepoPageController c;
  late final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    c = Get.put(ExtensionRepoPageController());
    super.initState();
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
          final isSelected = c.searchType.value == cat['type'];
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
                c.searchType.value = type;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _content() {
    if (c.isLoading.value) {
      return const Center(child: ProgressRing());
    }
    if (c.isError.value) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'extension-repo.error'.i18n,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'extension-repo.error-tips'.i18n,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 20),
              PlatformFilledButton(
                child: Text('common.retry'.i18n),
                onPressed: () {
                  c.onRefresh();
                },
              )
            ],
          ),
        ),
      );
    }

    final extensionCards = c.extensions
        .map((e) => ExtensionCard(
            key: ValueKey(e['package']),
            name: e['name'],
            icon: e['icon'],
            version: e['version'],
            package: e['package'],
            lang: e['lang'],
            nsfw: e['nsfw'] == 'true',
            type: ExtensionType.values.firstWhere(
              (element) => element.toString() == 'ExtensionType.${e['type']}',
            )))
        .toList();

    // Filtering
    if (c.search.value.isNotEmpty) {
      extensionCards.removeWhere((element) =>
          !element.name.toLowerCase().contains(c.search.value.toLowerCase()) &&
          !element.package.toLowerCase().contains(c.search.value.toLowerCase()));
    }
    if (c.searchType.value != null) {
      extensionCards.removeWhere(
        (element) => element.type != c.searchType.value,
      );
    }

    if (extensionCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.extension_off_outlined,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'extension-repo.empty'.i18n,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return PlatformBuildWidget(
      androidBuilder: (context) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: extensionCards.length,
        itemBuilder: (context, index) => extensionCards[index],
      ),
      desktopBuilder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / 320).floor().clamp(1, 6);
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 130,
            ),
            itemCount: extensionCards.length,
            itemBuilder: (context, index) => extensionCards[index],
          );
        },
      ),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        title: 'common.extension-repo'.i18n,
        textEditingController: _searchController,
        onSubmitted: (value) {
          c.search.value = value;
        },
      ),
      body: Column(
        children: [
          Obx(() => _buildFilterChips(context)),
          Expanded(
            child: EasyRefresh(
              onRefresh: c.onRefresh,
              header: const ClassicHeader(
                showText: false,
                showMessage: false,
              ),
              child: Obx(_content),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'common.extension-repo'.i18n,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Category ComboBox Filter
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
                  value: c.searchType.value?.toString() ?? "all",
                  onChanged: (value) {
                    if (value == "all" || value == null) {
                      c.searchType.value = null;
                      return;
                    }
                    c.searchType.value = ExtensionType.values.firstWhere(
                      (element) => element.toString() == value,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Search Input Box
              SizedBox(
                width: 220,
                child: Obx(
                  () => fluent.TextBox(
                    controller: _searchController,
                    placeholder: 'common.search'.i18n,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(fluent.FluentIcons.search, size: 14),
                    ),
                    onChanged: (value) {
                      c.search.value = value;
                    },
                    onSubmitted: (value) {
                      c.search.value = value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              fluent.IconButton(
                icon: const Icon(fluent.FluentIcons.refresh),
                onPressed: () {
                  c.onRefresh();
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(_content),
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
