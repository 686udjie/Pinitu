import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/pin.dart';
import 'pin_fullscreen_page.dart';

class PinTile extends StatefulWidget {
  final PinItem pin;
  const PinTile({super.key, required this.pin});

  @override
  State<PinTile> createState() => _PinTileState();
}

class _PinTileState extends State<PinTile> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _ensureVideo() async {
    if (_videoInitialized) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.pin.mediaUrl),
    );
    await controller.initialize();
    controller.setLooping(true);
    setState(() {
      _videoController = controller;
      _videoInitialized = true;
    });
    await controller.play();
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PinFullscreenPage(pin: widget.pin)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.pin.isVideo) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          _videoInitialized && _videoController != null
              ? FittedBox(
                  fit: BoxFit.fitWidth,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : GestureDetector(
                  onTap: _ensureVideo,
                  child: const ColoredBox(
                    color: Color(0xFFE0DBD9),
                    child: Center(
                      child: Icon(Icons.play_circle_fill, size: 48),
                    ),
                  ),
                ),
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.videocam, size: 16, color: Colors.white),
            ),
          ),
        ],
      );
    } else {
      content = CachedNetworkImage(
        imageUrl: widget.pin.mediaUrl,
        fit: BoxFit.fitWidth,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        },
        placeholder: (c, _) => const ColoredBox(
          color: Color(0xFFE0DBD9),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (c, _, __) => const ColoredBox(
          color: Color(0xFFE0DBD9),
          child: Center(child: Icon(Icons.broken_image)),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: content,
    );
  }
}
