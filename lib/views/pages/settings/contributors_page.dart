import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/settings_controller.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ContributorItem {
  final String name;
  final String role;
  final String? avatarUrl;
  final String profileUrl;

  const ContributorItem({
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.profileUrl,
  });
}

class ContributorsPage extends StatefulWidget {
  const ContributorsPage({super.key});

  @override
  State<ContributorsPage> createState() => _ContributorsPageState();
}

class _ContributorsPageState extends State<ContributorsPage> {
  final SettingsController c = Get.put(SettingsController());

  static const List<ContributorItem> teamMembers = [
    ContributorItem(
      name: 'Krishna Vishwakarma',
      role: 'Lead Developer',
      avatarUrl: 'https://github.com/Krishna-Vishwakarma.png',
      profileUrl: 'https://github.com/Krishna-Vishwakarma',
    ),
    ContributorItem(
      name: 'NeighborhoodNerd',
      role: 'Contributor',
      avatarUrl: 'https://github.com/NeighborhoodNerd.png',
      profileUrl: 'https://github.com/NeighborhoodNerd',
    ),
    ContributorItem(
      name: 'Ombryal',
      role: 'Discord Head Admin · Contributor',
      avatarUrl: 'https://github.com/Ombryal.png',
      profileUrl: 'https://github.com/Ombryal',
    ),
  ];

  static const List<ContributorItem> communityMembers = [
    ContributorItem(
      name: 'Riyoc',
      role: 'New logo creator',
      avatarUrl: 'https://github.com/Riyoc.png',
      profileUrl: 'https://github.com/Riyoc',
    ),
    ContributorItem(
      name: 'mo7AmMeD64',
      role: 'Contributor',
      avatarUrl: 'https://github.com/mo7AmMeD64.png',
      profileUrl: 'https://github.com/mo7AmMeD64',
    ),
    ContributorItem(
      name: 'xayron',
      role: 'Contributor',
      avatarUrl: 'https://github.com/xayron.png',
      profileUrl: 'https://github.com/xayron',
    ),
    ContributorItem(
      name: 'Dev-next-gen',
      role: 'Contributor',
      avatarUrl: 'https://github.com/Dev-next-gen.png',
      profileUrl: 'https://github.com/Dev-next-gen',
    ),
  ];

  Widget _buildContributorCard(BuildContext context, ContributorItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? (Theme.of(context).scaffoldBackgroundColor == Colors.black
            ? const Color(0xFF141414)
            : const Color(0xFF1E1C1E))
        : Colors.white;

    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await launchUrl(
            Uri.parse(item.profileUrl),
            mode: LaunchMode.externalApplication,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.role,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_outward,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ContributorItem item) {
    if (item.avatarUrl != null && item.avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          item.avatarUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackAvatar(item.name),
        ),
      );
    }
    return _buildFallbackAvatar(item.name);
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Combine static community list with any dynamic contributors from Github
    final knownLogins = {
      ...teamMembers.map((e) => e.name.toLowerCase()),
      ...communityMembers.map((e) => e.name.toLowerCase()),
    };

    return Obx(() {
      final dynamicList = <ContributorItem>[];
      for (final item in c.contributors) {
        final login = (item['login'] ?? '').toString();
        if (login.isNotEmpty && !knownLogins.contains(login.toLowerCase())) {
          dynamicList.add(
            ContributorItem(
              name: login,
              role: 'Contributor',
              avatarUrl: item['avatar_url'] as String?,
              profileUrl: (item['html_url'] ?? 'https://github.com/$login').toString(),
            ),
          );
        }
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader('settings.team'.i18n),
          ...teamMembers.map((m) => _buildContributorCard(context, m)),
          _buildSectionHeader('settings.community-contributors'.i18n),
          ...communityMembers.map((m) => _buildContributorCard(context, m)),
          if (dynamicList.isNotEmpty)
            ...dynamicList.map((m) => _buildContributorCard(context, m)),
        ],
      );
    });
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.contributors'.i18n),
        centerTitle: true,
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: Text('settings.contributors'.i18n),
        leading: fluent.IconButton(
          icon: const Icon(fluent.FluentIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      content: _buildContent(context),
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
