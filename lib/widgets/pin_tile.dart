import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/pin.dart';
import 'download_notification.dart';
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
  late MethodChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = const MethodChannel('com.mousica.pinitu/gallery');
    if (widget.pin.isVideo) {
      _ensureVideo();
    }
  }

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
    controller.setVolume(0.0);
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

  Future<void> _downloadImage() async {
    final overlay = Overlay.of(context);
    final messageNotifier = ValueNotifier<String>('Downloading...');
    final iconNotifier = ValueNotifier<IconData>(Icons.download);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => DownloadNotification(
        messageNotifier: messageNotifier,
        iconNotifier: iconNotifier,
      ),
    );
    overlay.insert(entry);

    try {
      if (widget.pin.isVideo) {
        // Save video to gallery
        final response = await Dio().get(
          widget.pin.mediaUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            },
          ),
        );
        try {
          await _channel.invokeMethod('saveToAlbum', {
            'bytes': response.data,
            'isVideo': true,
            'albumName': 'Pinitu',
          });
          messageNotifier.value = 'Video saved to Gallery';
          iconNotifier.value = Icons.check;
        } catch (e) {
          messageNotifier.value = 'Failed to save: $e';
          iconNotifier.value = Icons.error;
        }
      } else {
        // Save image to gallery
        final response = await Dio().get(
          widget.pin.mediaUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            },
          ),
        );
        try {
          await _channel.invokeMethod('saveToAlbum', {
            'bytes': response.data,
            'isVideo': false,
            'albumName': 'Pinitu',
          });
          messageNotifier.value = 'Image saved to Gallery';
          iconNotifier.value = Icons.check;
        } catch (e) {
          messageNotifier.value = 'Failed to save: $e';
          iconNotifier.value = Icons.error;
        }
      }
    } catch (e) {
      messageNotifier.value = 'Download failed: $e';
      iconNotifier.value = Icons.error;
    }

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = widget.pin.aspectRatio ?? 0.75;
    Widget content;
    if (widget.pin.isVideo) {
      content = Stack(
        fit: StackFit.loose,
        children: [
          _videoInitialized && _videoController != null
              ? AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              : AspectRatio(
                  aspectRatio: aspectRatio,
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
        filterQuality: FilterQuality.high,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        },
        placeholder: (c, _) => AspectRatio(
          aspectRatio: aspectRatio,
          child: const ColoredBox(
            color: Color(0xFFE0DBD9),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        errorWidget: (c, _, __) => AspectRatio(
          aspectRatio: aspectRatio,
          child: const ColoredBox(
            color: Color(0xFFE0DBD9),
            child: Center(child: Icon(Icons.broken_image)),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      onLongPress: _downloadImage,
      child: content,
    );
  }
}
