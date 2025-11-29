import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
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
  void initState() {
    super.initState();
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Downloading...')));
    try {
      if (widget.pin.isVideo) {
        // For videos, save to gallery
        final tempDir = await getTemporaryDirectory();
        final uri = Uri.parse(widget.pin.mediaUrl);
        final filename = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'downloaded_video.mp4';
        final tempPath = '${tempDir.path}/$filename';
        await Dio().download(
          widget.pin.mediaUrl,
          tempPath,
          options: Options(
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            },
          ),
        );
        final result = await ImageGallerySaver.saveFile(tempPath);
        if (result['isSuccess']) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Video saved to Gallery')),
          );
        } else {
          throw Exception('Failed to save to gallery');
        }
      } else {
        // For images, save to gallery
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
        final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data),
        );
        if (result['isSuccess']) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Image saved to Gallery')),
          );
        } else {
          throw Exception('Failed to save to gallery');
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio =
        widget.pin.aspectRatio ?? 0.75; // Default aspect ratio if not available
    Widget content;
    if (widget.pin.isVideo) {
      content = Stack(
        fit: StackFit.loose,
        children: [
          _videoInitialized && _videoController != null
              ? AspectRatio(
                  aspectRatio: aspectRatio,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
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
