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

class _CoreTeamConfig {
  final int id;
  final String defaultLogin;
  final String name;
  final String role;

  const _CoreTeamConfig({
    required this.id,
    required this.defaultLogin,
    required this.name,
    required this.role,
  });
}

class ContributorsPage extends StatefulWidget {
  const ContributorsPage({super.key});

  @override
  State<ContributorsPage> createState() => _ContributorsPageState();
}

class _ContributorsPageState extends State<ContributorsPage> {
  final SettingsController c = Get.put(SettingsController());

  static const List<_CoreTeamConfig> coreTeamConfigs = [
    _CoreTeamConfig(
      id: 44718819,
      defaultLogin: 'MiaoMint',
      name: 'Miao Mint',
      role: 'Founder',
    ),
    _CoreTeamConfig(
      id: 95137948,
      defaultLogin: 'OshekharO',
      name: 'Saksham Shekher',
      role: 'App / Extension',
    ),
    _CoreTeamConfig(
      id: 56633229,
      defaultLogin: 'appdevelpo',
      name: 'Appdevelpo',
      role: 'App / Extension',
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
    return Obx(() {
      final teamList = <ContributorItem>[];
      final coreIds = coreTeamConfigs.map((e) => e.id.toString()).toSet();
      final coreLogins = coreTeamConfigs.map((e) => e.defaultLogin.toLowerCase()).toSet();

      for (final config in coreTeamConfigs) {
        Map<String, dynamic>? matched;
        for (final item in c.contributors) {
          final itemId = item['id']?.toString();
          final itemLogin = item['login']?.toString().toLowerCase();
          if ((itemId != null && itemId == config.id.toString()) ||
              (itemLogin != null && itemLogin == config.defaultLogin.toLowerCase())) {
            matched = item;
            break;
          }
        }

        final avatarUrl = matched?['avatar_url'] as String? ??
            'https://github.com/${config.defaultLogin}.png';
        final profileUrl = (matched?['html_url'] ??
                'https://github.com/${config.defaultLogin}')
            .toString();

        teamList.add(
          ContributorItem(
            name: config.name,
            role: config.role,
            avatarUrl: avatarUrl,
            profileUrl: profileUrl,
          ),
        );
      }

      final dynamicCommunityList = <ContributorItem>[];
      for (final item in c.contributors) {
        final itemId = item['id']?.toString();
        final itemLogin = item['login']?.toString().toLowerCase();

        final isCore = (itemId != null && coreIds.contains(itemId)) ||
            (itemLogin != null && coreLogins.contains(itemLogin));

        if (!isCore) {
          final login = (item['login'] ?? '').toString();
          if (login.isNotEmpty) {
            dynamicCommunityList.add(
              ContributorItem(
                name: login,
                role: 'Contributor',
                avatarUrl: item['avatar_url'] as String?,
                profileUrl:
                    (item['html_url'] ?? 'https://github.com/$login').toString(),
              ),
            );
          }
        }
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader('settings.team'.i18n),
          ...teamList.map((m) => _buildContributorCard(context, m)),
          _buildSectionHeader('settings.community-contributors'.i18n),
          if (dynamicCommunityList.isNotEmpty)
            ...dynamicCommunityList.map((m) => _buildContributorCard(context, m))
          else if (c.contributors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
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
    return PlatformWidget(
      androidWidget: _buildAndroid(context),
      desktopWidget: _buildDesktop(context),
    );
  }
}
