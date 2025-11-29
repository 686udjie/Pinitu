import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/pin.dart';
import 'download_notification.dart';

class PinFullscreenPage extends StatefulWidget {
  final PinItem pin;
  const PinFullscreenPage({super.key, required this.pin});

  @override
  State<PinFullscreenPage> createState() => _PinFullscreenPageState();
}

class _PinFullscreenPageState extends State<PinFullscreenPage>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  late MethodChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = const MethodChannel('com.mousica.pinitu/gallery');
    if (widget.pin.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.pin.mediaUrl),
    );
    await controller.initialize();
    controller.setVolume(1.0);
    controller.setLooping(true);
    _isMuted = false;
    setState(() {
      _videoController = controller;
      _videoInitialized = true;
      _isPlaying = true;
    });
    await controller.play();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _downloadMedia() async {
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
          if (widget.pin.isVideo)
            IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: _toggleMute,
            ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: widget.pin.isVideo ? _buildVideoView() : _buildImageView(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageView() {
    return InteractiveViewer(
      child: CachedNetworkImage(
        imageUrl: widget.pin.mediaUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
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
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          if (!_isPlaying)
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
