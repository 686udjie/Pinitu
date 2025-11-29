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

class _PinFullscreenPageState extends State<PinFullscreenPage>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showNotification = false;
  String _notificationMessage = '';
  IconData _notificationIcon = Icons.download;
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _downloadMedia() async {
    setState(() {
      _showNotification = true;
      _notificationMessage = 'Downloading...';
      _notificationIcon = Icons.download;
    });
    _animationController.forward();
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
        setState(() {
          _notificationMessage = 'Video downloaded to Downloads';
          _notificationIcon = Icons.check;
        });
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
          setState(() {
            _notificationMessage = 'Image saved to Gallery';
            _notificationIcon = Icons.check;
          });
        } else {
          throw Exception('Failed to save to gallery');
        }
      }
      Future.delayed(const Duration(seconds: 2), () {
        _animationController.reverse().then((_) {
          setState(() {
            _showNotification = false;
          });
        });
      });
    } catch (e) {
      setState(() {
        _notificationMessage = 'Download failed: $e';
        _notificationIcon = Icons.error;
      });
      Future.delayed(const Duration(seconds: 2), () {
        _animationController.reverse().then((_) {
          setState(() {
            _showNotification = false;
          });
        });
      });
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
          if (_showNotification) _buildNotification(),
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
              fit: BoxFit.fitWidth,
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

  Widget _buildNotification() {
    return SlideTransition(
      position: _animation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _notificationIcon,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                _notificationMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
