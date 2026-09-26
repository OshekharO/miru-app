import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/settings_controller.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/application.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/pages/settings/contributors_page.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/settings/settings_card_group.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late SettingsController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(SettingsController());
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icon/logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Miru',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version v${packageInfo.version}',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    return [
      _buildHeader(context),
      SettingsCardGroup(
        children: [
          SettingsTile(
            icon: const Icon(Icons.people_outline, size: 20),
            iconBgColor: const Color(0xFF3B82F6),
            title: 'settings.contributors'.i18n,
            buildSubtitle: () => 'View developers and community contributors',
            onTap: () {
              if (Platform.isAndroid) {
                Get.to(() => const ContributorsPage());
              } else {
                router.push('/settings/contributors');
              }
            },
          ),
        ],
      ),
      SettingsCardGroup(
        title: 'Social',
        children: [
          SettingsTile(
            icon: const Icon(Icons.language, size: 20),
            iconBgColor: const Color(0xFF10B981),
            title: 'Website',
            buildSubtitle: () => c.links['Website'] ?? 'https://miru.js.org',
            onTap: () {
              final url = c.links['Website'];
              if (url != null) {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
          SettingsTile(
            icon: const Icon(Icons.send, size: 20),
            iconBgColor: const Color(0xFF0EA5E9),
            title: 'Telegram',
            buildSubtitle: () => 'Community chat',
            onTap: () {
              launchUrl(
                Uri.parse('https://t.me/MiruChat'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          SettingsTile(
            icon: const Icon(Icons.code, size: 20),
            iconBgColor: const Color(0xFF8B5CF6),
            title: 'GitHub',
            buildSubtitle: () => 'View the source code',
            onTap: () {
              launchUrl(
                Uri.parse('https://github.com/OshekharO/miru-app'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ],
      ),
      SettingsCardGroup(
        title: 'App',
        children: [
          SettingsTile(
            icon: const Icon(Icons.system_update, size: 20),
            iconBgColor: const Color(0xFFEC4899),
            title: 'settings.upgrade'.i18n,
            buildSubtitle: () => 'Check if new version is available',
            onTap: () {
              ApplicationUtils.checkUpdate(context, showSnackbar: true);
            },
          ),
          SettingsTile(
            icon: const Icon(Icons.verified_user_outlined, size: 20),
            iconBgColor: const Color(0xFFF59E0B),
            title: 'Licenses',
            buildSubtitle: () => 'Open source licenses',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Miru',
                applicationVersion: 'v${packageInfo.version}',
              );
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.about'.i18n),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: _buildContent(context),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return fluent.ScaffoldPage.scrollable(
      header: fluent.PageHeader(
        title: Text('settings.about'.i18n),
      ),
      children: _buildContent(context),
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
