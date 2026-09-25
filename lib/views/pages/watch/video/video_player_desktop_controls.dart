import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:miru_app/controllers/watch/video_controller.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';
import 'package:miru_app/views/widgets/watch/playlist.dart';
import 'package:window_manager/window_manager.dart';

class VideoPlayerDesktopControls extends StatefulWidget {
  const VideoPlayerDesktopControls({
    super.key,
    required this.controller,
  });
  final VideoPlayerController controller;

  @override
  State<VideoPlayerDesktopControls> createState() =>
      _VideoPlayerDesktopControlsState();
}

class _VideoPlayerDesktopControlsState
    extends State<VideoPlayerDesktopControls> {
  late final _c = widget.controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  bool _showControls = true;
  final _subtitleViewKey = GlobalKey<SubtitleViewState>();

  void _updateTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    final timeoutSeconds = _c.controlsTimeoutSeconds.value;
    if (timeoutSeconds <= 0) return;

    _timer = Timer(
      Duration(seconds: timeoutSeconds),
      () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _updateTimer(),
      child: FluentTheme(
        data: FluentThemeData(
          brightness: Brightness.dark,
        ),
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (value) {
            if (value is KeyDownEvent) {
              _c.keyboardShortcuts[value.logicalKey]?.call();
            }
          },
          child: Stack(
            children: [
              // Subtitle Layer
              Positioned.fill(
                child: Obx(
                  () {
                    final textStyle = TextStyle(
                      height: 1.4,
                      fontSize: _c.subtitleFontSize.value,
                      letterSpacing: 0.0,
                      wordSpacing: 0.0,
                      color: _c.subtitleFontColor.value,
                      fontWeight: _c.subtitleFontWeight.value,
                      backgroundColor:
                          _c.subtitleBackgroundColor.value.withOpacity(
                        _c.subtitleBackgroundOpacity.value,
                      ),
                    );
                    _subtitleViewKey.currentState?.textAlign =
                        _c.subtitleTextAlign.value;
                    _subtitleViewKey.currentState?.style = textStyle;
                    _subtitleViewKey.currentState?.padding =
                        EdgeInsets.fromLTRB(
                      16.0,
                      0.0,
                      16.0,
                      _showControls ? 110.0 : 20.0,
                    );
                    return SubtitleView(
                      controller: _c.videoController,
                      configuration: SubtitleViewConfiguration(
                        style: textStyle,
                        textAlign: _c.subtitleTextAlign.value,
                      ),
                      key: _subtitleViewKey,
                    );
                  },
                ),
              ),

              // Center Loading / Error Overlay
              Positioned.fill(
                child: Center(
                  child: Obx(() {
                    if (_c.error.value.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'video.streamlink-error'.i18n,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Button(
                                  child: Text('common.error-message'.i18n),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => ContentDialog(
                                        constraints: const BoxConstraints(
                                          maxWidth: 500,
                                        ),
                                        title: Text('common.error-message'.i18n),
                                        content: SelectableText(_c.error.value),
                                        actions: [
                                          Button(
                                            child: Text('common.close'.i18n),
                                            onPressed: () => router.pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  child: Text('common.retry'.i18n),
                                  onPressed: () {
                                    _c.error.value = '';
                                    _c.play();
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }
                    if (!_c.isGettingWatchData.value) {
                      return StreamBuilder(
                        stream: _c.player.stream.buffering,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data! ||
                              _c.player.state.buffering) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const ProgressRing(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_c.runtime.extension.icon != null)
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              margin: const EdgeInsets.only(right: 12),
                              child: CacheNetWorkImagePic(
                                _c.runtime.extension.icon!,
                                width: 32,
                                height: 32,
                              ),
                            ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _c.runtime.extension.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'video.getting-streamlink'.i18n,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // Controls Overlay (Header & Footer)
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Column(
                      children: [
                        // Header
                        _Header(
                          title: _c.title,
                          episode: _c.playList[_c.index.value].name,
                          onClose: () {
                            if (_c.isFullScreen.value) {
                              WindowManager.instance.setFullScreen(false);
                            }
                            router.pop();
                          },
                        ),

                        const Spacer(),

                        // Footer
                        _Footer(controller: _c),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({
    required this.title,
    required this.episode,
    required this.onClose,
  });
  final String title;
  final String episode;
  final VoidCallback onClose;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _isAlwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    WindowManager.instance.isAlwaysOnTop().then((value) {
      if (mounted) {
        setState(() {
          _isAlwaysOnTop = value;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_isAlwaysOnTop) {
      WindowManager.instance.setAlwaysOnTop(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.episode,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.75),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Tooltip(
            message: _isAlwaysOnTop ? 'Unpin window' : 'Pin window on top',
            child: IconButton(
              icon: Icon(
                _isAlwaysOnTop ? FluentIcons.pinned : FluentIcons.pin,
                size: 16,
              ),
              onPressed: () async {
                await WindowManager.instance.setAlwaysOnTop(!_isAlwaysOnTop);
                setState(() {
                  _isAlwaysOnTop = !_isAlwaysOnTop;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Minimize',
            child: IconButton(
              icon: const Icon(
                FluentIcons.chrome_minimize,
                size: 14,
              ),
              onPressed: () {
                WindowManager.instance.minimize();
              },
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Close player',
            child: IconButton(
              onPressed: widget.onClose,
              icon: const Icon(
                FluentIcons.chevron_down,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.controller,
  });
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeline & SeekBar
          Row(
            children: [
              StreamBuilder<Duration>(
                stream: controller.player.stream.position,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return Text(
                    '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SeekBar(controller: controller),
              ),
              const SizedBox(width: 12),
              StreamBuilder<Duration>(
                stream: controller.player.stream.duration,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Text(
                    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Control Actions
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Action Group: Volume & Quality
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Volume(
                        value: controller.player.state.volume,
                        onVolumeChanged: (value) {
                          controller.player.setVolume(value);
                        },
                      ),
                      Obx(() {
                        if (controller.currentQuality.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _Quality(controller: controller),
                        );
                      }),
                    ],
                  ),
                ),

                // Center Action Group: Prev, Play/Pause, Next
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(
                      () => Tooltip(
                        message: 'Previous Episode',
                        child: IconButton(
                          onPressed: controller.index.value > 0
                              ? () => controller.index.value--
                              : null,
                          icon: const Icon(
                            FluentIcons.previous,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<bool>(
                      stream: controller.player.stream.playing,
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? controller.player.state.playing;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: controller.playOrPause,
                            icon: Icon(
                              playing ? FluentIcons.pause : FluentIcons.play,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => Tooltip(
                        message: 'Next Episode',
                        child: IconButton(
                          onPressed: controller.playList.length - 1 > controller.index.value
                              ? () => controller.index.value++
                              : null,
                          icon: const Icon(
                            FluentIcons.next,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Right Action Group: Speed, Torrent, Tracks, Playlist, Fullscreen, Settings
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (constraints.maxWidth > 650)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _Speed(controller: controller),
                        ),
                      if (constraints.maxWidth > 650)
                        Obx(() {
                          if (controller.torrentMediaFileList.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _TorrentFiles(controller: controller),
                          );
                        }),
                      Tooltip(
                        message: 'Audio / Subtitle Tracks',
                        child: _Track(controller: controller),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Playlist',
                        child: _Episode(controller: controller),
                      ),
                      const SizedBox(width: 6),
                      Obx(
                        () => Tooltip(
                          message: controller.isFullScreen.value
                              ? 'Exit Fullscreen'
                              : 'Fullscreen',
                          child: IconButton(
                            onPressed: () => controller.toggleFullscreen(),
                            icon: Icon(
                              controller.isFullScreen.value
                                  ? FluentIcons.back_to_window
                                  : FluentIcons.full_screen,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Player Settings',
                        child: IconButton(
                          onPressed: () {
                            controller.showSidebar.value = !controller.showSidebar.value;
                          },
                          icon: const Icon(
                            FluentIcons.settings,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Volume extends StatefulWidget {
  const _Volume({
    required this.value,
    required this.onVolumeChanged,
  });
  final double value;
  final Function(double value) onVolumeChanged;

  @override
  State<_Volume> createState() => _VolumeState();
}

class _VolumeState extends State<_Volume> {
  final _flyoutController = FlyoutController();
  final _volume = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _volume.value = widget.value;
  }

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _flyoutController,
      child: IconButton(
        icon: Obx(
          () => Icon(
            _volume.value == 0
                ? FluentIcons.volume0
                : _volume.value < 50
                    ? FluentIcons.volume1
                    : _volume.value < 100
                        ? FluentIcons.volume2
                        : FluentIcons.volume3,
            size: 18,
          ),
        ),
        onPressed: () {
          _flyoutController.showFlyout(
            barrierDismissible: false,
            dismissOnPointerMoveAway: true,
            builder: (context) {
              return FluentTheme(
                data: FluentThemeData.dark(),
                child: FlyoutContent(
                  useAcrylic: true,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(
                          () => Icon(
                            _volume.value == 0
                                ? FluentIcons.volume0
                                : _volume.value < 50
                                    ? FluentIcons.volume1
                                    : _volume.value < 100
                                        ? FluentIcons.volume2
                                        : FluentIcons.volume3,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Obx(
                          () => SizedBox(
                            width: 120,
                            height: 30,
                            child: Slider(
                              value: _volume.value,
                              max: 100,
                              onChanged: (val) {
                                _volume.value = val;
                                widget.onVolumeChanged(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Obx(
                          () => Text(
                            '${_volume.value.toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Episode extends StatefulWidget {
  const _Episode({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_Episode> createState() => _EpisodeState();
}

class _EpisodeState extends State<_Episode> {
  final _flyoutController = FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FluentTheme(
      data: FluentThemeData.dark(),
      child: FlyoutTarget(
        controller: _flyoutController,
        child: IconButton(
          icon: const Icon(FluentIcons.playlist_music, size: 18),
          onPressed: () {
            _flyoutController.showFlyout(
              barrierDismissible: false,
              dismissOnPointerMoveAway: true,
              builder: (context) {
                return FluentTheme(
                  data: FluentThemeData.dark(),
                  child: FlyoutContent(
                    padding: const EdgeInsets.all(0),
                    useAcrylic: true,
                    child: Container(
                      width: 300,
                      constraints: const BoxConstraints(maxHeight: 450),
                      child: PlayList(
                        title: widget.controller.title,
                        list: widget.controller.playList
                            .map((e) => e.name)
                            .toList(),
                        selectIndex: widget.controller.index.value,
                        onChange: (value) {
                          widget.controller.index.value = value;
                          router.pop();
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Quality extends StatefulWidget {
  const _Quality({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_Quality> createState() => _QualityState();
}

class _QualityState extends State<_Quality> {
  final _flyoutController = FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _flyoutController,
      child: Button(
        style: ButtonStyle(
          padding: ButtonState.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
        child: Text(
          widget.controller.currentQuality.value,
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: () {
          if (widget.controller.qualityMap.isEmpty) {
            widget.controller.sendMessage(
              Message(Text("video.no-qualities".i18n)),
            );
            return;
          }
          _flyoutController.showFlyout(
            barrierDismissible: false,
            dismissOnPointerMoveAway: true,
            builder: (context) {
              return FluentTheme(
                data: FluentThemeData.dark(),
                child: FlyoutContent(
                  useAcrylic: true,
                  child: Container(
                    width: 180,
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView(
                      children: [
                        for (final quality in widget.controller.qualityMap.entries)
                          ListTile(
                            title: Text(quality.key),
                            onPressed: () {
                              widget.controller.switchQuality(quality.value);
                              router.pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Track extends StatefulWidget {
  const _Track({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_Track> createState() => _TrackState();
}

class _TrackState extends State<_Track> {
  final _flyoutController = FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _flyoutController,
      child: IconButton(
        icon: const Icon(FluentIcons.locale_language, size: 18),
        onPressed: () {
          _flyoutController.showFlyout(
            barrierDismissible: false,
            dismissOnPointerMoveAway: true,
            builder: (context) {
              return FluentTheme(
                data: FluentThemeData.dark(),
                child: FlyoutContent(
                  useAcrylic: true,
                  padding: const EdgeInsets.all(0),
                  child: Container(
                    width: 240,
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "video.subtitle".i18n,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ListTile.selectable(
                          selected: SubtitleTrack.no() ==
                              widget.controller.player.state.track.subtitle,
                          title: Text('common.off'.i18n),
                          onPressed: () {
                            widget.controller.setSubtitleTrack(SubtitleTrack.no());
                            router.pop();
                          },
                        ),
                        ListTile.selectable(
                          title: Text('video.subtitle-file'.i18n),
                          onPressed: () {
                            widget.controller.addSubtitleFile();
                          },
                        ),
                        for (final subtitle in widget.controller.subtitles)
                          ListTile.selectable(
                            selected: subtitle ==
                                widget.controller.player.state.track.subtitle,
                            title: Text(subtitle.title ?? ''),
                            subtitle: Text(subtitle.language ?? ''),
                            onPressed: () {
                              widget.controller.setSubtitleTrack(subtitle);
                              router.pop();
                            },
                          ),
                        for (final subtitle
                            in widget.controller.player.state.tracks.subtitle)
                          if (subtitle != SubtitleTrack.no() &&
                              (subtitle.language != null || subtitle.title != null))
                            ListTile.selectable(
                              selected: subtitle ==
                                  widget.controller.player.state.track.subtitle,
                              title: Text(subtitle.title ?? ''),
                              subtitle: Text(subtitle.language ?? ''),
                              onPressed: () {
                                widget.controller.setSubtitleTrack(subtitle);
                                router.pop();
                              },
                            ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "video.audio".i18n,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final audio
                            in widget.controller.player.state.tracks.audio)
                          if (audio.language != null || audio.title != null)
                            ListTile.selectable(
                              selected: audio ==
                                  widget.controller.player.state.track.audio,
                              title: Text(audio.title ?? ''),
                              subtitle: Text(audio.language ?? ''),
                              onPressed: () {
                                widget.controller.player.setAudioTrack(audio);
                                router.pop();
                              },
                            ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TorrentFiles extends StatefulWidget {
  const _TorrentFiles({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_TorrentFiles> createState() => _TorrentFilesState();
}

class _TorrentFilesState extends State<_TorrentFiles> {
  final _flyoutController = FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _flyoutController,
      child: IconButton(
        icon: const Icon(FluentIcons.folder_open, size: 18),
        onPressed: () {
          _flyoutController.showFlyout(
            barrierDismissible: false,
            dismissOnPointerMoveAway: true,
            builder: (context) {
              return FluentTheme(
                data: FluentThemeData.dark(),
                child: FlyoutContent(
                  useAcrylic: true,
                  padding: const EdgeInsets.all(0),
                  child: Container(
                    width: 280,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final file in widget.controller.torrentMediaFileList)
                          ListTile.selectable(
                            title: Text(
                              file,
                              style: const TextStyle(fontSize: 13),
                            ),
                            selected:
                                widget.controller.currentTorrentFile.value == file,
                            onPressed: () {
                              widget.controller.playTorrentFile(file);
                              router.pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Speed extends StatefulWidget {
  const _Speed({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_Speed> createState() => _SpeedState();
}

class _SpeedState extends State<_Speed> {
  final _flyoutController = FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _flyoutController,
      child: Button(
        style: ButtonStyle(
          padding: ButtonState.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
        child: Obx(() => Text(
              '${widget.controller.currentSpeed.value}x',
              style: const TextStyle(fontSize: 12),
            )),
        onPressed: () {
          _flyoutController.showFlyout(
            barrierDismissible: false,
            dismissOnPointerMoveAway: true,
            builder: (context) {
              return FluentTheme(
                data: FluentThemeData.dark(),
                child: FlyoutContent(
                  useAcrylic: true,
                  padding: const EdgeInsets.all(0),
                  child: Container(
                    width: 140,
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView(
                      padding: const EdgeInsets.all(6),
                      children: [
                        for (final speed in widget.controller.speedList)
                          ListTile.selectable(
                            title: Text(
                              '${speed}x',
                              style: const TextStyle(fontSize: 13),
                            ),
                            selected:
                                widget.controller.currentSpeed.value == speed,
                            onPressed: () {
                              widget.controller.player.setRate(speed);
                              widget.controller.currentSpeed.value = speed;
                              router.pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  Duration position = const Duration();
  Duration duration = const Duration();
  bool _isDrag = false;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration>? durationSubscription;

  @override
  void initState() {
    super.initState();
    positionSubscription =
        widget.controller.player.stream.position.listen((event) {
      if (!_isDrag) {
        setState(() {
          position = event;
        });
      }
    });
    durationSubscription =
        widget.controller.player.stream.duration.listen((event) {
      setState(() {
        duration = event;
      });
    });
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    durationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = duration.inSeconds < position.inSeconds
        ? position.inSeconds.toDouble()
        : duration.inSeconds.toDouble();

    return Slider(
      value: (position.inSeconds).toDouble().clamp(0.0, maxVal > 0 ? maxVal : 1.0),
      max: maxVal > 0 ? maxVal : 1.0,
      label:
          '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
      onChanged: (value) {
        _isDrag = true;
        setState(() {
          position = Duration(seconds: value.toInt());
        });
      },
      onChangeEnd: (value) {
        _isDrag = false;
        widget.controller.player.seek(
          Duration(seconds: value.toInt()),
        );
      },
    );
  }
}
