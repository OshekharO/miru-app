import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:miru_app/controllers/watch/video_controller.dart';
import 'package:miru_app/utils/color.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

enum SidebarTab {
  episodes,
  qualitys,
  torrentFiles,
  tracks,
  settings,
}

String _sidebarTabToString(SidebarTab tab) {
  return "video.sidebar.tab.${tab.name}".i18n;
}

IconData _sidebarTabToIcon(SidebarTab tab) {
  switch (tab) {
    case SidebarTab.episodes:
      return Icons.playlist_play_rounded;
    case SidebarTab.qualitys:
      return Icons.high_quality_rounded;
    case SidebarTab.torrentFiles:
      return Icons.folder_open_rounded;
    case SidebarTab.tracks:
      return Icons.subtitles_rounded;
    case SidebarTab.settings:
      return Icons.tune_rounded;
  }
}

class VideoPlayerSidebar extends StatefulWidget {
  const VideoPlayerSidebar({
    super.key,
    required this.controller,
  });
  final VideoPlayerController controller;

  @override
  State<VideoPlayerSidebar> createState() => _VideoPlayerSidebarState();
}

class _VideoPlayerSidebarState extends State<VideoPlayerSidebar> {
  late final _c = widget.controller;

  List<SidebarTab> get _availableTabs {
    final tabs = <SidebarTab>[SidebarTab.episodes];
    if (_c.torrentMediaFileList.isNotEmpty) {
      tabs.add(SidebarTab.torrentFiles);
    }
    if (_c.qualityMap.isNotEmpty) {
      tabs.add(SidebarTab.qualitys);
    }
    tabs.add(SidebarTab.tracks);
    tabs.add(SidebarTab.settings);
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final availableTabs = _availableTabs;
    final initialTab = _c.initSidebarTab.value;
    final initialIndex = availableTabs.contains(initialTab)
        ? availableTabs.indexOf(initialTab)
        : 0;

    final isBlackTheme =
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final panelBgColor = isBlackTheme
        ? Colors.black
        : const Color(0xFF121214).withOpacity(0.96);

    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: isBlackTheme ? Colors.black : const Color(0xFF121214),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: isBlackTheme ? const Color(0xFF161618) : const Color(0xFF161618),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: panelBgColor,
          border: const Border(
            left: BorderSide(
              color: Colors.white10,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: DefaultTabController(
          length: availableTabs.length,
          initialIndex: initialIndex,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context);
              return Column(
                children: [
                  // Modern Header Bar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white10,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.dashboard_customize_rounded,
                          size: 20,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: tabController,
                            builder: (context, _) {
                              final currentTab =
                                  availableTabs[tabController.index];
                              return Text(
                                _sidebarTabToString(currentTab),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              );
                            },
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _c.showSidebar.value = false;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Segmented / Pill Tab Bar Navigation
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      padding: EdgeInsets.zero,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      tabs: availableTabs.map((tab) {
                        return Tab(
                          height: 32,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _sidebarTabToIcon(tab),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(_sidebarTabToString(tab)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Main Tab Content
                  Expanded(
                    child: TabBarView(
                      children: availableTabs.map((tab) {
                        switch (tab) {
                          case SidebarTab.episodes:
                            return _EpisodesList(controller: _c);
                          case SidebarTab.qualitys:
                            return _QualitySelector(controller: _c);
                          case SidebarTab.torrentFiles:
                            return _TorrentFiles(controller: _c);
                          case SidebarTab.tracks:
                            return _TrackSelector(controller: _c);
                          case SidebarTab.settings:
                            return _SideBarSettings(controller: _c);
                        }
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SideBarSettings extends StatefulWidget {
  const _SideBarSettings({
    required this.controller,
  });
  final VideoPlayerController controller;

  @override
  State<_SideBarSettings> createState() => _SideBarSettingsState();
}

class _SideBarSettingsState extends State<_SideBarSettings> {
  late final _c = widget.controller;

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildColorPickerRow({
    required String label,
    required Color currentColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final color in ColorUtils.baseColors) ...[
                GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: currentColor == color
                          ? Border.all(color: Colors.white, width: 2.5)
                          : Border.all(color: Colors.white12, width: 1),
                      boxShadow: currentColor == color
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: currentColor == color
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        // Subtitle Settings Card
        _buildSectionCard(
          title: 'video.sidebar.subtitle.title'.i18n,
          icon: Icons.subtitles_outlined,
          children: [
            // Font Size
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'video.sidebar.subtitle.font-size'.i18n,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Obx(
                  () => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_c.subtitleFontSize.value.toStringAsFixed(0)} px',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Obx(
              () => SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.blueAccent,
                ),
                child: Slider(
                  value: _c.subtitleFontSize.value,
                  onChanged: (value) {
                    _c.subtitleFontSize.value = value;
                  },
                  min: 20,
                  max: 80,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Font Color
            Obx(
              () => _buildColorPickerRow(
                label: 'video.sidebar.subtitle.font-color'.i18n,
                currentColor: _c.subtitleFontColor.value,
                onColorSelected: (color) {
                  _c.subtitleFontColor.value = color;
                },
              ),
            ),
            const SizedBox(height: 12),

            // Background Color
            Obx(
              () => _buildColorPickerRow(
                label: 'video.sidebar.subtitle.background-color'.i18n,
                currentColor: _c.subtitleBackgroundColor.value,
                onColorSelected: (color) {
                  _c.subtitleBackgroundColor.value = color;
                },
              ),
            ),
            const SizedBox(height: 12),

            // Background Opacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'video.sidebar.subtitle.background-opacity'.i18n,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Obx(
                  () => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${(_c.subtitleBackgroundOpacity.value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Obx(
              () => SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.blueAccent,
                ),
                child: Slider(
                  value: _c.subtitleBackgroundOpacity.value,
                  onChanged: (value) {
                    _c.subtitleBackgroundOpacity.value = value;
                  },
                  min: 0,
                  max: 1,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Text Alignment Segmented Control
            Text(
              'video.sidebar.subtitle.text-align'.i18n,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    for (final align in const [
                      TextAlign.justify,
                      TextAlign.left,
                      TextAlign.center,
                      TextAlign.right,
                    ]) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _c.subtitleTextAlign.value = align;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _c.subtitleTextAlign.value == align
                                  ? Colors.blueAccent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              align == TextAlign.justify
                                  ? Icons.format_align_justify_rounded
                                  : align == TextAlign.left
                                      ? Icons.format_align_left_rounded
                                      : align == TextAlign.right
                                          ? Icons.format_align_right_rounded
                                          : Icons.format_align_center_rounded,
                              size: 18,
                              color: _c.subtitleTextAlign.value == align
                                  ? Colors.white
                                  : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Font Weight Segmented Control
            Text(
              'video.sidebar.subtitle.font-weight'.i18n,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _c.subtitleFontWeight.value = FontWeight.normal;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _c.subtitleFontWeight.value ==
                                    FontWeight.normal
                                ? Colors.blueAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'video.sidebar.subtitle.font-weight-normal'.i18n,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: _c.subtitleFontWeight.value ==
                                      FontWeight.normal
                                  ? Colors.white
                                  : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _c.subtitleFontWeight.value = FontWeight.bold;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                _c.subtitleFontWeight.value == FontWeight.bold
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'video.sidebar.subtitle.font-weight-bold'.i18n,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _c.subtitleFontWeight.value == FontWeight.bold
                                      ? Colors.white
                                      : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Playback Mode Card
        _buildSectionCard(
          title: 'video.sidebar.play-mode.title'.i18n,
          icon: Icons.repeat_rounded,
          children: [
            Obx(
              () => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildPlayModePill(
                      mode: PlaylistMode.loop,
                      label: 'video.sidebar.play-mode.loop'.i18n,
                      icon: Icons.repeat_one_rounded,
                    ),
                    _buildPlayModePill(
                      mode: PlaylistMode.single,
                      label: 'video.sidebar.play-mode.single'.i18n,
                      icon: Icons.looks_one_rounded,
                    ),
                    _buildPlayModePill(
                      mode: PlaylistMode.none,
                      label: 'video.sidebar.play-mode.auto-next'.i18n,
                      icon: Icons.skip_next_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayModePill({
    required PlaylistMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _c.playMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _c.playMode.value = mode;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodesList extends StatelessWidget {
  const _EpisodesList({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Obx(
        () => ScrollablePositionedList.builder(
          itemCount: controller.playList.length,
          initialScrollIndex: controller.index.value,
          itemBuilder: (context, index) {
            final episode = controller.playList[index];
            final isSelected = controller.index.value == index;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    controller.index.value = index;
                    controller.showSidebar.value = false;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blueAccent.withOpacity(0.18)
                          : const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSelected
                                ? const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            episode.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color:
                                  isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Playing',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        for (final quality in controller.qualityMap.entries) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  controller.switchQuality(quality.value);
                  controller.showSidebar.value = false;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hd_rounded,
                        size: 20,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          quality.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrackSelector extends StatelessWidget {
  const _TrackSelector({required this.controller});
  final VideoPlayerController controller;

  Widget _buildSubHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 10, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent.withOpacity(0.18)
                  : const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.blueAccent.withOpacity(0.5)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.blueAccent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        _buildSubHeader('video.subtitle'.i18n, Icons.subtitles_rounded),
        _buildTrackTile(
          title: 'common.off'.i18n,
          isSelected:
              SubtitleTrack.no() == controller.player.state.track.subtitle,
          onTap: () {
            controller.setSubtitleTrack(SubtitleTrack.no());
            controller.showSidebar.value = false;
          },
        ),
        _buildTrackTile(
          title: 'video.subtitle-file'.i18n,
          isSelected: false,
          onTap: () {
            controller.addSubtitleFile();
            controller.showSidebar.value = false;
          },
        ),
        for (final subtitle in controller.subtitles)
          _buildTrackTile(
            title: subtitle.title ?? 'video.subtitle'.i18n,
            subtitle: subtitle.language,
            isSelected:
                subtitle == controller.player.state.track.subtitle,
            onTap: () {
              controller.setSubtitleTrack(subtitle);
              controller.showSidebar.value = false;
            },
          ),
        for (final subtitle in controller.player.state.tracks.subtitle)
          if (subtitle != SubtitleTrack.no() &&
              (subtitle.language != null || subtitle.title != null))
            _buildTrackTile(
              title: subtitle.title ?? 'video.subtitle'.i18n,
              subtitle: subtitle.language,
              isSelected:
                  subtitle == controller.player.state.track.subtitle,
              onTap: () {
                controller.setSubtitleTrack(subtitle);
                controller.showSidebar.value = false;
              },
            ),
        const SizedBox(height: 10),
        _buildSubHeader('video.audio'.i18n, Icons.audiotrack_rounded),
        for (final audio in controller.player.state.tracks.audio)
          if (audio.language != null || audio.title != null)
            _buildTrackTile(
              title: audio.title ?? 'video.audio'.i18n,
              subtitle: audio.language,
              isSelected: audio == controller.player.state.track.audio,
              onTap: () {
                controller.player.setAudioTrack(audio);
                controller.showSidebar.value = false;
              },
            ),
      ],
    );
  }
}

class _TorrentFiles extends StatelessWidget {
  const _TorrentFiles({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        for (final file in controller.torrentMediaFileList) ...[
          Obx(() {
            final isSelected = controller.currentTorrentFile.value == file;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    controller.playTorrentFile(file);
                    controller.showSidebar.value = false;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blueAccent.withOpacity(0.18)
                          : const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          size: 18,
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white54,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            file,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: Colors.blueAccent,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
