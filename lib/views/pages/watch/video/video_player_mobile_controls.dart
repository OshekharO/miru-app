import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:miru_app/controllers/watch/video_controller.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/router.dart';
import 'package:miru_app/views/pages/watch/video/video_player_cast.dart';
import 'package:miru_app/views/pages/watch/video/video_player_sidebar.dart';
import 'package:miru_app/views/widgets/cache_network_image.dart';
import 'package:miru_app/views/widgets/progress.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class VideoPlayerMobileControls extends StatefulWidget {
  const VideoPlayerMobileControls({super.key, required this.controller});
  final VideoPlayerController controller;

  @override
  State<VideoPlayerMobileControls> createState() =>
      _VideoPlayerMobileControlsState();
}

class _VideoPlayerMobileControlsState
    extends State<VideoPlayerMobileControls> {
  late final VideoPlayerController _c = widget.controller;
  final _subtitleViewKey = GlobalKey<SubtitleViewState>();
  bool _showControls = true;
  double _currentBrightness = 0;
  double _currentVolume = 0;
  // 是否是调整亮度
  bool _isBrightness = false;
  // 是否正在调节
  bool _isAdjusting = false;
  // 滑动时的进度
  Duration _position = Duration.zero;
  // 是否左右滑动调整进度
  bool _isSeeking = false;
  // 是否长按加速
  bool _isLongPress = false;
  // 双击求快进/快退的动画反馈
  bool _showDoubleTapFeedback = false;
  bool _isDoubleTapForward = true;
  int _accumulatedDoubleTapCount = 0;
  Timer? _doubleTapFeedbackTimer;
  // 定时器
  Timer? _timer;

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

  void _triggerDoubleTapFeedback(bool forward) {
    _doubleTapFeedbackTimer?.cancel();
    if (_showDoubleTapFeedback && _isDoubleTapForward == forward) {
      _accumulatedDoubleTapCount++;
    } else {
      _accumulatedDoubleTapCount = 1;
    }
    setState(() {
      _showDoubleTapFeedback = true;
      _isDoubleTapForward = forward;
    });
    _doubleTapFeedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showDoubleTapFeedback = false;
          _accumulatedDoubleTapCount = 0;
        });
      }
    });
  }

  Future<void> _init() async {
    _updateTimer();
    VolumeController().showSystemUI = false;
    try {
      _currentBrightness = await ScreenBrightness().current;
    } catch (_) {}
    try {
      _currentVolume = await VolumeController().getVolume();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _doubleTapFeedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doubleTapSeconds = _c.doubleTapSeekSeconds.value;
    final totalSeekSeconds = doubleTapSeconds * (_accumulatedDoubleTapCount > 0 ? _accumulatedDoubleTapCount : 1);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
      ),
      child: Theme(
        data: ThemeData.dark(useMaterial3: true),
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
                  _subtitleViewKey.currentState?.padding = EdgeInsets.fromLTRB(
                    16.0,
                    0.0,
                    16.0,
                    _showControls ? 95.0 : 16.0,
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

            // Top Status & Adjustment Badges Overlay
            Positioned(
              top: 36,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _isSeeking
                      ? Container(
                          key: const ValueKey('seeking_badge'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withOpacity(0.75),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fast_forward, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                ' / ${_c.duration.value.inMinutes}:${(_c.duration.value.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _isLongPress
                          ? Container(
                              key: const ValueKey('long_press_badge'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black.withOpacity(0.75),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.speed,
                                      size: 18, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(
                                    'Playing at 3x speed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _isAdjusting
                              ? Container(
                                  key: const ValueKey('adjusting_badge'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.black.withOpacity(0.75),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isBrightness) ...[
                                        const Icon(Icons.brightness_6, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(_currentBrightness * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      ] else ...[
                                        Icon(
                                          _currentVolume == 0
                                              ? Icons.volume_off
                                              : Icons.volume_up,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(_currentVolume * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      ],
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                ),
              ),
            ),

            // Double Tap Ripple Feedback Badge
            if (_showDoubleTapFeedback)
              Positioned.fill(
                child: Align(
                  alignment: _isDoubleTapForward
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDoubleTapForward
                              ? Icons.fast_forward
                              : Icons.fast_rewind,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_isDoubleTapForward ? '+' : '-'}${totalSeekSeconds}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Main Gesture Handler Layer
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_showControls) {
                    setState(() {
                      _showControls = false;
                    });
                    return;
                  }
                  _updateTimer();
                },
                onDoubleTapDown: (details) {
                  final dx = details.localPosition.dx;
                  final width = screenWidth > 0 ? screenWidth / 3 : 100.0;
                  if (dx < width) {
                    _c.doubleTapSeek(false);
                    _triggerDoubleTapFeedback(false);
                  } else if (dx > width * 2) {
                    _c.doubleTapSeek(true);
                    _triggerDoubleTapFeedback(true);
                  } else {
                    _c.playOrPause();
                  }
                },
                onVerticalDragStart: (details) {
                  final width = screenWidth > 0 ? screenWidth : 300.0;
                  _isBrightness = details.localPosition.dx < width / 2;
                },
                onVerticalDragUpdate: (details) {
                  final height = screenHeight > 0 ? screenHeight : 400.0;
                  final add = details.delta.dy / (height * 0.8);
                  if (_isBrightness) {
                    _currentBrightness =
                        clampDouble(_currentBrightness - add, 0.0, 1.0);
                    ScreenBrightness().setScreenBrightness(_currentBrightness);
                  } else {
                    _currentVolume = clampDouble(_currentVolume - add, 0.0, 1.0);
                    VolumeController().setVolume(_currentVolume);
                  }
                  _isAdjusting = true;
                  setState(() {});
                },
                onHorizontalDragStart: (details) {
                  _position = _c.position.value;
                },
                onVerticalDragEnd: (details) {
                  _isAdjusting = false;
                  setState(() {});
                },
                onHorizontalDragUpdate: (details) {
                  final width = screenWidth > 0 ? screenWidth : 300.0;
                  double scale = 200000 / width;
                  Duration pos = _position +
                      Duration(
                        milliseconds: (details.delta.dx * scale).round(),
                      );
                  _position = Duration(
                    milliseconds: pos.inMilliseconds.clamp(
                      0,
                      _c.duration.value.inMilliseconds,
                    ),
                  );
                  _isSeeking = true;
                  setState(() {});
                },
                onHorizontalDragEnd: (details) {
                  _c.seek(_position);
                  _isSeeking = false;
                  setState(() {});
                },
                onLongPressStart: (details) {
                  _isLongPress = true;
                  _c.player.setRate(3.0);
                  setState(() {});
                },
                onLongPressEnd: (details) {
                  _c.player.setRate(_c.currentSpeed.value);
                  _isLongPress = false;
                  setState(() {});
                },
                child: const SizedBox.expand(),
              ),
            ),

            // Center Content (Buffering / Error / Loading)
            Positioned.fill(
              child: Center(
                child: Obx(() {
                  if (_c.error.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "video.streamlink-error".i18n,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.tonal(
                                child: Text('common.error-message'.i18n),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('common.error-message'.i18n),
                                      content: SelectableText(_c.error.value),
                                      actions: [
                                        FilledButton(
                                          child: Text('common.close'.i18n),
                                          onPressed: () => Get.back(),
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
                    return StreamBuilder<bool>(
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
                        if (_c.dlnaDevice.value != null) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  FlutterI18n.translate(
                                    context,
                                    'video.cast-device',
                                    translationParams: {
                                      'device': _c
                                          .dlnaDevice.value!.info.friendlyName,
                                    },
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FilledButton(
                                  onPressed: () {
                                    _c.disconnectDLNADevice();
                                  },
                                  child: Text('common.disconnect'.i18n),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'video.getting-streamlink'.i18n,
                              style: TextStyle(
                                fontSize: 13,
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

            // Header Control Overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -90,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: _Header(controller: _c),
              ),
            ),

            // Footer Control Overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: _Footer(controller: _c),
              ),
            ),

            // Sidebar Backdrop Overlay
            Positioned.fill(
              child: Obx(
                () {
                  if (!_c.showSidebar.value) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    child: Container(
                      color: Colors.black54,
                    ),
                    onTap: () {
                      _c.showSidebar.value = false;
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              RouterUtils.pop();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() {
              final data = controller.playList[controller.index.value];
              final episode = data.name;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    episode,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.75),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }),
          ),

          // DLNA Cast Button
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (context) {
                  return DraggableScrollableSheet(
                    expand: false,
                    builder: (context, scrollController) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        child: VideoPlayerCast(
                          onDeviceSelected: (device) {
                            controller.connectDLNADevice(device);
                            Get.back();
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          // Quick Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              controller.toggleSideBar(SidebarTab.settings);
            },
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black87,
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SeekBar(controller: controller),
          const SizedBox(height: 8),
          Row(
            children: [
              // Prev
              Obx(
                () => IconButton(
                  icon: const Icon(Icons.skip_previous, size: 22),
                  onPressed: controller.index.value > 0
                      ? () => controller.index.value--
                      : null,
                ),
              ),

              // Play / Pause Button
              Obx(() {
                final playing = controller.isPlaying.value;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: controller.playOrPause,
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      size: 26,
                    ),
                  ),
                );
              }),

              // Next
              Obx(
                () => IconButton(
                  icon: const Icon(Icons.skip_next, size: 22),
                  onPressed:
                      controller.playList.length - 1 > controller.index.value
                          ? () => controller.index.value++
                          : null,
                ),
              ),
              const SizedBox(width: 8),

              // Position / Duration Text
              Obx(() {
                final position = controller.position.value;
                final duration = controller.duration.value;
                return Text(
                  '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')} / ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                  ),
                );
              }),

              const Spacer(),

              // Quality Chip Button
              Obx(() {
                if (controller.currentQuality.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilledButton.tonal(
                    onPressed: () {
                      if (controller.qualityMap.isEmpty) {
                        controller.sendMessage(
                          Message(Text('video.no-qualities'.i18n)),
                        );
                        return;
                      }
                      controller.toggleSideBar(SidebarTab.qualitys);
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      minimumSize: MaterialStateProperty.all(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      controller.currentQuality.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),

              // Speed Picker Menu
              Obx(
                () => PopupMenuButton<double>(
                  initialValue: controller.currentSpeed.value,
                  onSelected: (val) {
                    controller.currentSpeed.value = val;
                  },
                  itemBuilder: (context) => [
                    for (final speed in controller.speedList)
                      PopupMenuItem(
                        value: speed,
                        child: Text('${speed}x'),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${controller.currentSpeed.value}x',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Torrent Files Button
              Obx(() {
                if (controller.torrentMediaFileList.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  onPressed: () {
                    controller.toggleSideBar(SidebarTab.torrentFiles);
                  },
                  icon: const Icon(Icons.video_file, size: 20),
                );
              }),

              // Tracks Button
              IconButton(
                onPressed: () {
                  controller.toggleSideBar(SidebarTab.tracks);
                },
                icon: const Icon(Icons.subtitles, size: 20),
              ),

              // Episodes List Button
              IconButton(
                icon: const Icon(Icons.playlist_play, size: 22),
                onPressed: () {
                  controller.toggleSideBar(SidebarTab.episodes);
                },
              ),
            ],
          ),
        ],
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
  bool _isSliderDragging = false;
  Duration _position = Duration.zero;
  Duration _buffer = Duration.zero;

  StreamSubscription? _bufferSubscription;

  @override
  void initState() {
    super.initState();
    _buffer = widget.controller.player.state.buffer;
    _bufferSubscription =
        widget.controller.player.stream.buffer.listen((event) {
      if (mounted) {
        setState(() {
          _buffer = event;
        });
      }
    });
  }

  @override
  void dispose() {
    _bufferSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 6,
          ),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 12,
          ),
          activeTrackColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor: Colors.white.withOpacity(0.2),
          secondaryActiveTrackColor: Colors.white.withOpacity(0.4),
        ),
        child: Obx(
          () {
            final duration = widget.controller.duration.value.inMilliseconds;
            int position = widget.controller.position.value.inMilliseconds;
            if (_isSliderDragging) {
              position = _position.inMilliseconds;
            }

            final maxVal = duration > 0 ? duration.toDouble() : 1.0;

            return Slider(
              min: 0,
              max: maxVal,
              value: clampDouble(
                position.toDouble(),
                0,
                maxVal,
              ),
              secondaryTrackValue: clampDouble(
                _buffer.inMilliseconds.toDouble(),
                0,
                maxVal,
              ),
              onChanged: (value) {
                if (_isSliderDragging) {
                  setState(() {
                    _position = Duration(milliseconds: value.toInt());
                  });
                }
              },
              onChangeStart: (value) {
                _position = Duration(milliseconds: value.toInt());
                _isSliderDragging = true;
              },
              onChangeEnd: (value) {
                if (_isSliderDragging) {
                  widget.controller.seek(
                    Duration(milliseconds: value.toInt()),
                  );
                  _isSliderDragging = false;
                }
              },
            );
          },
        ),
      ),
    );
  }
}
