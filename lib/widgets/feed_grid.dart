import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/pin.dart';
import '../parsers/pinterest_parser.dart';
import '../services/client_handler.dart';
import 'pin_tile.dart';

class FeedGrid extends StatefulWidget {
  const FeedGrid({super.key});

  @override
  State<FeedGrid> createState() => _FeedGridState();
}

class _FeedGridState extends State<FeedGrid> with ClientHandler {
  final List<PinItem> _pins = <PinItem>[];
  final List<PinItem> _upcomingPins = <PinItem>[];
  final Set<String> _seenUrls = <String>{};
  bool _loading = false;
  bool _refreshing = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    initializeClient().then((_) {
      setState(() {});
      _loadCurrentPage(reset: true).then((_) => _loadUpcoming());
    });
  }

  Future<void> _loadCurrentPage({bool reset = false}) async {
    if (_loading || _refreshing) return;
    setState(() {
      _loading = true;
    });
    try {
      if (reset) {
        _pins.clear();
        _upcomingPins.clear();
        _seenUrls.clear();
        _page = 1;
      }
      final html = _page == 1
          ? await client.fetchHomeHtml()
          : await client.fetchHomeHtmlPage(_page);
      final newPins = PinterestParser.parseHomeHtml(html);
      for (final p in newPins) {
        final key = p.canonicalUrl;
        if (_seenUrls.add(key)) {
          _pins.add(p);
        }
      }
      _preloadImages(newPins);
      _page += 1;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadUpcoming() async {
    if (_loading || _refreshing) return;
    try {
      final html = await client.fetchHomeHtmlPage(_page);
      final newPins = PinterestParser.parseHomeHtml(html);
      _upcomingPins.clear();
      for (final p in newPins) {
        final key = p.canonicalUrl;
        if (_seenUrls.add(key)) {
          _upcomingPins.add(p);
        }
      }
      _preloadImages(_upcomingPins);
      _page += 1;
    } catch (e) {
      // Silently handle errors for background loading
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
    });
    try {
      final html = await client.fetchHomeHtml();
      final newPins = PinterestParser.parseHomeHtml(html);
      setState(() {
        _pins.clear();
        _upcomingPins.clear();
        _seenUrls.clear();
        for (final p in newPins) {
          final key = p.canonicalUrl;
          if (_seenUrls.add(key)) {
            _pins.add(p);
          }
        }
        _page = 2; // Since we loaded page 1
      });
      _preloadImages(newPins);
      _loadUpcoming();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  void _preloadImages(List<PinItem> pins) {
    for (final pin in pins) {
      if (!pin.isVideo) {
        // Preload image
        precacheImage(
          CachedNetworkImageProvider(
            pin.mediaUrl,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            },
          ),
          context,
        );
      }
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pins.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No pins found.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  _loadCurrentPage(reset: true).then((_) => _loadUpcoming()),
              child: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = _getCrossAxisCount(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 800 && !_loading) {
          if (_upcomingPins.isNotEmpty) {
            setState(() {
              _pins.addAll(_upcomingPins);
              _upcomingPins.clear();
            });
            _loadUpcoming();
          } else {
            _loadCurrentPage();
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: MasonryGridView.count(
          padding: const EdgeInsets.all(8),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount:
              _pins.length + (_loading ? crossAxisCount : 0), 
          itemBuilder: (context, index) {
            if (index < _pins.length) {
              final pin = _pins[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PinTile(pin: pin),
              );
            } else {
              // Loading placeholder
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  color: const Color(0xFFE0DBD9),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
