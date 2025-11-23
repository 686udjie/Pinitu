import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/pin.dart';

class PinFullscreenPage extends StatefulWidget {
  final PinItem pin;
  const PinFullscreenPage({super.key, required this.pin});

  @override
  State<PinFullscreenPage> createState() => _PinFullscreenPageState();
}

class _PinFullscreenPageState extends State<PinFullscreenPage> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.pin.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
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

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _downloadMedia() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Downloading...')));
    try {
      if (widget.pin.isVideo) {
        // For videos, save to downloads
        final dir = await getDownloadsDirectory();
        if (dir == null) throw Exception('No downloads directory');
        final uri = Uri.parse(widget.pin.mediaUrl);
        final filename = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'downloaded_video';
        final savePath = '${dir.path}/$filename';
        await Dio().download(
          widget.pin.mediaUrl,
          savePath,
          options: Options(
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            },
          ),
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Video downloaded to Downloads')),
        );
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.pin.title ?? 'Pin',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadMedia,
          ),
        ],
      ),
      body: SizedBox.expand(
        child: widget.pin.isVideo ? _buildVideoView() : _buildImageView(),
      ),
    );
  }

  Widget _buildImageView() {
    return InteractiveViewer(
      child: CachedNetworkImage(
        imageUrl: widget.pin.mediaUrl,
        fit: BoxFit.contain,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        },
        placeholder: (c, _) => const Center(child: CircularProgressIndicator()),
        errorWidget: (c, _, __) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.white)),
      ),
    );
  }

  Widget _buildVideoView() {
    if (!_videoInitialized || _videoController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _videoController!.value.size.width,
        height: _videoController!.value.size.height,
        child: VideoPlayer(_videoController!),
      ),
    );
  }
}
