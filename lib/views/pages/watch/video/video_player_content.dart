import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:miru_app/controllers/watch/video_controller.dart';
import 'package:miru_app/views/pages/watch/video/video_player_desktop_controls.dart';
import 'package:miru_app/views/pages/watch/video/video_player_mobile_controls.dart';

class VideoPlayerConten extends StatelessWidget {
  const VideoPlayerConten({
    super.key,
    required this.tag,
  });
  final String tag;

  BoxFit _getBoxFit(String fitMode) {
    switch (fitMode) {
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<VideoPlayerController>(tag: tag);
    return Obx(() {
      final fit = _getBoxFit(c.videoFitMode.value);
      return Video(
        controller: c.videoController,
        fit: fit,
        subtitleViewConfiguration: const SubtitleViewConfiguration(
          visible: false,
        ),
        controls: (state) {
          if (Platform.isAndroid) {
            return VideoPlayerMobileControls(
              controller: c,
            );
          }
          return VideoPlayerDesktopControls(
            controller: c,
          );
        },
      );
    });
  }
}
