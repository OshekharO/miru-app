import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:miru_app/data/providers/tmdb_provider.dart';
import 'package:miru_app/controllers/application_controller.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/request.dart';
import 'package:miru_app/views/dialogs/bt_dialog.dart';
import 'package:miru_app/controllers/extension/extension_repo_controller.dart';
import 'package:miru_app/controllers/settings_controller.dart';
import 'package:miru_app/views/pages/settings/about_page.dart';
import 'package:miru_app/views/pages/tracking/anilist_tracking_page.dart';
import 'package:miru_app/views/widgets/settings/settings_card_group.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_input_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_switch_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_numberbox_button.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';
import 'package:miru_app/views/widgets/settings/comic_cache_settings.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/application.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tmdb_api/tmdb_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsController c;

  @override
  void initState() {
    c = Get.put(SettingsController());
    super.initState();
  }

  List<Widget> _buildContent() {
    return [
      if (!Platform.isAndroid) ...[
        Text(
          'common.settings'.i18n,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
      ],

      // 常规设置 Card Group
      SettingsCardGroup(
        children: [
          SettingsExpanderTile(
            icon: fluent.FluentIcons.developer_tools,
            androidIcon: Icons.tune,
            iconBgColor: const Color(0xFF3B82F6), // Blue
            title: 'settings.general'.i18n,
            subTitle: 'settings.general-subtitle'.i18n,
            content: Column(
              children: [
                // TMDB KEY 设置
                SettingsIntpuTile(
                  title: 'settings.tmdb-key'.i18n,
                  buildSubtitle: () {
                    if (!Platform.isAndroid) {
                      return 'settings.tmdb-key-subtitle'.i18n;
                    }
                    final key =
                        MiruStorage.getSetting(SettingKey.tmdbKey) as String;
                    if (key.isEmpty) {
                      return 'common.unset'.i18n;
                    }
                    return key.replaceAll(RegExp(r"."), '*');
                  },
                  onChanged: (value) {
                    MiruStorage.setSetting(SettingKey.tmdbKey, value);
                    TmdbApi.tmdb = TMDB(
                      ApiKeys(value, ''),
                      defaultLanguage:
                          MiruStorage.getSetting(SettingKey.language),
                    );
                  },
                  buildText: () {
                    return MiruStorage.getSetting(SettingKey.tmdbKey);
                  },
                ),
                // 语言设置
                SettingsRadiosTile(
                  title: 'settings.language'.i18n,
                  itemNameValue: {
                    'languages.be'.i18n: 'be',
                    'languages.en'.i18n: 'en',
                    'languages.es'.i18n: 'es',
                    'languages.fr'.i18n: 'fr',
                    'languages.hu'.i18n: 'hu',
                    'languages.hi'.i18n: 'hi',
                    'languages.id'.i18n: 'id',
                    'languages.ja'.i18n: 'ja',
                    'languages.pl'.i18n: 'pl',
                    'languages.ru'.i18n: 'ru',
                    'languages.ryu'.i18n: 'ryu',
                    'languages.uk'.i18n: 'uk',
                    'languages.zh'.i18n: 'zh',
                    'languages.zhHant'.i18n: 'zhHant',
                  },
                  buildSubtitle: () => 'settings.language-subtitle'.i18n,
                  applyValue: (value) {
                    MiruStorage.setSetting(SettingKey.language, value);
                    I18nUtils.changeLanguage(value);
                  },
                  buildGroupValue: () {
                    return MiruStorage.getSetting(SettingKey.language);
                  },
                ),
                // 主题设置
                SettingsRadiosTile(
                  title: 'settings.theme'.i18n,
                  itemNameValue: () {
                    final map = {
                      'settings.theme-system'.i18n: 'system',
                      'settings.theme-light'.i18n: 'light',
                      'settings.theme-dark'.i18n: 'dark',
                    };
                    if (Platform.isAndroid) {
                      map['settings.theme-black'.i18n] = 'black';
                    }
                    return map;
                  }(),
                  buildSubtitle: () => 'settings.theme-subtitle'.i18n,
                  applyValue: (value) {
                    Get.find<ApplicationController>().changeTheme(value);
                  },
                  buildGroupValue: () {
                    return Get.find<ApplicationController>().themeText.value;
                  },
                ),
                // 启动检查更新
                SettingsSwitchTile(
                  title: 'settings.auto-check-update'.i18n,
                  buildSubtitle: () =>
                      'settings.auto-check-update-subtitle'.i18n,
                  buildValue: () =>
                      MiruStorage.getSetting(SettingKey.autoCheckUpdate),
                  onChanged: (value) {
                    MiruStorage.setSetting(SettingKey.autoCheckUpdate, value);
                  },
                ),
                // NSFW
                SettingsSwitchTile(
                  title: 'settings.nsfw'.i18n,
                  buildSubtitle: () => "settings.nsfw-subtitle".i18n,
                  buildValue: () {
                    return MiruStorage.getSetting(SettingKey.enableNSFW);
                  },
                  onChanged: (value) {
                    MiruStorage.setSetting(SettingKey.enableNSFW, value);
                  },
                ),
              ],
            ),
          ),
          // 扩展仓库
          SettingsExpanderTile(
            icon: fluent.FluentIcons.repo,
            androidIcon: Icons.extension,
            iconBgColor: const Color(0xFF10B981), // Green
            title: 'settings.extension'.i18n,
            subTitle: 'settings.extension-subtitle'.i18n,
            content: Column(
              children: [
                SettingsIntpuTile(
                  title: 'settings.repo-url'.i18n,
                  buildSubtitle: () {
                    if (!Platform.isAndroid) {
                      return 'settings.repo-url-subtitle'.i18n;
                    }
                    return MiruStorage.getSetting(SettingKey.miruRepoUrl);
                  },
                  onChanged: (value) {
                    MiruStorage.setSetting(SettingKey.miruRepoUrl, value);
                    Get.find<ExtensionRepoPageController>().onRefresh();
                  },
                  buildText: () {
                    return MiruStorage.getSetting(SettingKey.miruRepoUrl);
                  },
                ),
              ],
            ),
          ),
          // 视频播放器
          SettingsExpanderTile(
            icon: fluent.FluentIcons.play,
            androidIcon: Icons.play_arrow,
            iconBgColor: const Color(0xFF6366F1), // Indigo
            title: 'settings.video-player'.i18n,
            subTitle: 'settings.video-player-subtitle'.i18n,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsTile(
                  title: 'settings.bt-server'.i18n,
                  buildSubtitle: () => "settings.bt-server-subtitle".i18n,
                  trailing: PlatformWidget(
                    androidWidget: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const BTDialog(),
                        );
                      },
                      child: Text('settings.bt-server-manager'.i18n),
                    ),
                    desktopWidget: fluent.FilledButton(
                      onPressed: () {
                        fluent.showDialog(
                          context: context,
                          builder: (context) => const BTDialog(),
                        );
                      },
                      child: Text('settings.bt-server-manager'.i18n),
                    ),
                  ),
                ),
                SettingsRadiosTile(
                  title: 'settings.external-player'.i18n,
                  itemNameValue: () {
                    if (Platform.isAndroid) {
                      return {
                        "settings.external-player-builtin".i18n: "built-in",
                        "VLC": "vlc",
                        "Other": "other",
                      };
                    }
                    if (Platform.isLinux) {
                      return {
                        "settings.external-player-builtin".i18n: "built-in",
                        "VLC": "vlc",
                        "mpv": "mpv",
                      };
                    }
                    return {
                      "settings.external-player-builtin".i18n: "built-in",
                      "VLC": "vlc",
                      "PotPlayer": "potplayer",
                    };
                  }(),
                  buildSubtitle: () => FlutterI18n.translate(
                    context,
                    'settings.external-player-subtitle',
                    translationParams: {
                      'player': MiruStorage.getSetting(SettingKey.videoPlayer),
                    },
                  ),
                  applyValue: (value) {
                    MiruStorage.setSetting(SettingKey.videoPlayer, value);
                  },
                  buildGroupValue: () {
                    return MiruStorage.getSetting(SettingKey.videoPlayer);
                  },
                ),
                SettingsRadiosTile(
                  title: 'settings.controls-timeout'.i18n,
                  itemNameValue: const {
                    '3s': 3,
                    '5s': 5,
                    '10s': 10,
                    '15s': 15,
                  },
                  buildSubtitle: () => 'settings.controls-timeout-subtitle'.i18n,
                  applyValue: (value) {
                    MiruStorage.setSetting(SettingKey.controlsTimeout, value);
                  },
                  buildGroupValue: () {
                    return MiruStorage.getSetting(SettingKey.controlsTimeout) ?? 3;
                  },
                ),
                SettingsRadiosTile(
                  title: 'settings.double-tap-seek'.i18n,
                  itemNameValue: const {
                    '5s': 5,
                    '10s': 10,
                    '15s': 15,
                    '30s': 30,
                  },
                  buildSubtitle: () => 'settings.double-tap-seek-subtitle'.i18n,
                  applyValue: (value) {
                    MiruStorage.setSetting(SettingKey.doubleTapSeekDuration, value);
                  },
                  buildGroupValue: () {
                    return MiruStorage.getSetting(SettingKey.doubleTapSeekDuration) ?? 10;
                  },
                ),
                if (!Platform.isAndroid) ...[
                  const SizedBox(height: 10),
                  Text("settings.skip-interval".i18n),
                  const SizedBox(height: 2),
                  Text(
                    "settings.skip-interval-subtitle".i18n,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  Column(
                    children: [
                      Row(children: [
                        Expanded(
                            child: SettingNumboxButton(
                          title: "key I",
                          button1text: "1s",
                          button2text: "0.1s",
                          onChanged: (value) {
                            MiruStorage.setSetting(
                                SettingKey.keyI, value ??= -10.0);
                          },
                          numberBoxvalue:
                              MiruStorage.getSetting(SettingKey.keyI) ?? -10.0,
                        )),
                        const SizedBox(width: 30),
                        Expanded(
                            child: SettingNumboxButton(
                          title: "key J",
                          button1text: "1s",
                          button2text: "0.1s",
                          onChanged: (value) {
                            MiruStorage.setSetting(SettingKey.keyJ, value ??= 10.0);
                          },
                          numberBoxvalue:
                              MiruStorage.getSetting(SettingKey.keyJ) ?? 10.0,
                        ))
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: SettingNumboxButton(
                            title: "arrow left",
                            icon: const Icon(fluent.FluentIcons.chevron_left_med),
                            button1text: "1s",
                            button2text: "0.1s",
                            numberBoxvalue:
                                MiruStorage.getSetting(SettingKey.arrowLeft) ??
                                    10.0,
                            onChanged: (value) {
                              MiruStorage.setSetting(
                                  SettingKey.arrowLeft, value ??= -2.0);
                            },
                          )),
                          const SizedBox(width: 30),
                          Expanded(
                              child: SettingNumboxButton(
                            title: "arrow right",
                            icon: const Icon(fluent.FluentIcons.chevron_right_med),
                            button1text: "1s",
                            button2text: "0.1s",
                            onChanged: (value) {
                              MiruStorage.setSetting(
                                  SettingKey.arrowRight, value ??= 2);
                            },
                            numberBoxvalue:
                                MiruStorage.getSetting(SettingKey.arrowRight) ??
                                    10.0,
                          ))
                        ],
                      )
                    ],
                  ),
                ]
              ],
            ),
          ),
          // 漫画阅读器设置
          SettingsExpanderTile(
            icon: fluent.FluentIcons.reading_mode,
            androidIcon: Icons.menu_book,
            iconBgColor: const Color(0xFFF59E0B), // Amber
            title: 'settings.comic-reader'.i18n,
            subTitle: 'settings.comic-reader-subtitle'.i18n,
            content: Column(
              children: [
                SettingsRadiosTile(
                  title: 'settings.default-reader-mode'.i18n,
                  itemNameValue: () {
                    final map = {
                      'comic-settings.standard'.i18n: 'standard',
                      'comic-settings.right-to-left'.i18n: 'rightToLeft',
                      'comic-settings.web-toon'.i18n: 'webTonn',
                    };
                    return map;
                  }(),
                  buildSubtitle: () {
                    final mode = MiruStorage.getSetting(SettingKey.readingMode);
                    switch (mode) {
                      case 'rightToLeft':
                        return 'comic-settings.right-to-left'.i18n;
                      case 'webTonn':
                        return 'comic-settings.web-toon'.i18n;
                      case 'standard':
                      default:
                        return 'comic-settings.standard'.i18n;
                    }
                  },
                  applyValue: (value) {
                    MiruStorage.setSetting(SettingKey.readingMode, value);
                  },
                  buildGroupValue: () {
                    return MiruStorage.getSetting(SettingKey.readingMode);
                  },
                ),
                const SizedBox(height: 10),
                const ComicCacheSettings(),
              ],
            ),
          ),
          // 同步数据
          SettingsExpanderTile(
            icon: fluent.FluentIcons.sync,
            androidIcon: Icons.sync,
            iconBgColor: const Color(0xFF8B5CF6), // Purple
            title: 'settings.tracking'.i18n,
            subTitle: 'settings.tracking-subtitle'.i18n,
            content: Column(
              children: [
                SettingsSwitchTile(
                  title: 'settings.auto-tracking'.i18n,
                  buildSubtitle: () => 'settings.auto-tracking-subtitle'.i18n,
                  buildValue: () {
                    return MiruStorage.getSetting(SettingKey.autoTracking);
                  },
                  onChanged: (value) {
                    MiruStorage.setSetting(SettingKey.autoTracking, value);
                  },
                ),
                SettingsTile(
                  icon: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/icon/anilist.jpg'),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  title: 'Anilist',
                  onTap: () {
                    if (!Platform.isAndroid) {
                      router.push('/settings/anilist');
                    } else {
                      Get.to(() => const AniListTrackingPage());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      // 高级 / Advanced Card Group
      SettingsCardGroup(
        title: 'settings.advanced'.i18n,
        children: [
          // 网络设置
          SettingsExpanderTile(
            icon: fluent.FluentIcons.globe,
            androidIcon: Icons.wifi,
            iconBgColor: const Color(0xFF0EA5E9), // Sky Blue
            title: "settings.network".i18n,
            subTitle: "settings.network-subtitle".i18n,
            content: Column(
              children: [
                SettingsIntpuTile(
                  title: 'settings.network-ua'.i18n,
                  buildSubtitle: () {
                    if (!Platform.isAndroid) {
                      return 'settings.network-ua-subtitle'.i18n;
                    }
                    return MiruStorage.getUASetting();
                  },
                  onChanged: (value) {
                    MiruStorage.setUASetting(value);
                  },
                  buildText: () {
                    return MiruStorage.getUASetting();
                  },
                ),
                SettingsRadiosTile(
                  title: 'settings.proxy-type'.i18n,
                  itemNameValue: {
                    'settings.proxy-type-direct'.i18n: 'DIRECT',
                    'settings.proxy-type-socks5'.i18n: 'SOCKS5',
                    'settings.proxy-type-socks4'.i18n: 'SOCKS4',
                    'settings.proxy-type-http'.i18n: 'PROXY',
                  },
                  buildSubtitle: () => 'settings.proxy-type-subtitle'.i18n,
                  applyValue: (value) {
                    MiruStorage.setSetting(SettingKey.proxyType, value);
                    MiruRequest.refreshProxy();
                  },
                  buildGroupValue: () {
                    return MiruStorage.getSetting(SettingKey.proxyType);
                  },
                ),
                SettingsIntpuTile(
                  title: 'settings.proxy'.i18n,
                  buildSubtitle: () => 'settings.proxy-subtitle'.i18n,
                  onChanged: (value) {
                    MiruStorage.setSetting(SettingKey.proxy, value);
                    MiruRequest.refreshProxy();
                  },
                  buildText: () {
                    return MiruStorage.getSetting(SettingKey.proxy);
                  },
                ),
              ],
            ),
          ),
          // Debug Log
          SettingsExpanderTile(
            title: "settings.log".i18n,
            subTitle: 'settings.log-subtitle'.i18n,
            androidIcon: Icons.bug_report,
            icon: fluent.FluentIcons.report_alert,
            iconBgColor: const Color(0xFFEF4444), // Red
            content: Column(
              children: [
                SettingsSwitchTile(
                  title: 'settings.save-log'.i18n,
                  buildSubtitle: () => 'settings.save-log-subtitle'.i18n,
                  buildValue: () {
                    return MiruStorage.getSetting(SettingKey.saveLog);
                  },
                  onChanged: (value) {
                    MiruStorage.setSetting(SettingKey.saveLog, value);
                  },
                ),
                // 导出日志
                SettingsTile(
                  title: 'settings.export-log'.i18n,
                  buildSubtitle: () => 'settings.export-log-subtitle'.i18n,
                  trailing: PlatformWidget(
                    androidWidget: TextButton(
                      onPressed: () {
                        Share.shareXFiles([XFile(MiruLog.logFilePath)]);
                      },
                      child: Text('common.export'.i18n),
                    ),
                    desktopWidget: fluent.FilledButton(
                      onPressed: () async {
                        final path = await FilePicker.platform.saveFile(
                          type: FileType.custom,
                          allowedExtensions: ['log'],
                          fileName: 'miru.log',
                        );
                        if (path != null) {
                          File(MiruLog.logFilePath).copy(path);
                        }
                      },
                      child: Text('common.export'.i18n),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!Platform.isAndroid)
            Obx(
              () {
                final value = c.extensionLogWindowId.value != -1;
                return SettingsSwitchTile(
                  icon: const Icon(fluent.FluentIcons.bug, size: 20),
                  iconBgColor: const Color(0xFF64748B), // Slate
                  title: 'settings.extension-log'.i18n,
                  buildSubtitle: () => 'settings.extension-log-subtitle'.i18n,
                  buildValue: () => value,
                  onChanged: (value) {
                    c.toggleExtensionLogWindow(value);
                  },
                );
              },
            ),
        ],
      ),

      // 关于 / About Card Group
      SettingsCardGroup(
        title: 'settings.about'.i18n,
        children: [
          SettingsTile(
            icon: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icon/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            title: 'settings.about'.i18n,
            buildSubtitle: () => 'Version v${packageInfo.version}',
            onTap: () {
              if (Platform.isAndroid) {
                Get.to(() => const AboutPage());
              } else {
                router.push('/settings/about');
              }
            },
          ),
        ],
      )
    ];
  }

  Widget _buildAndroid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFEFF2F6),
      appBar: AppBar(
        title: Text('common.settings'.i18n),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: _buildContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuildWidget(
      androidBuilder: _buildAndroid,
      desktopBuilder: (context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        children: _buildContent(),
      ),
    );
  }
}
