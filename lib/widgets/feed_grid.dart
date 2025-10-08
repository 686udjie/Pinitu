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
  final Set<String> _seenUrls = <String>{};
  bool _loading = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    initializeClient().then((_) {
      setState(() {});
      _loadMore(reset: true);
    });
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    try {
      if (reset) {
        _pins.clear();
        _seenUrls.clear();
        _page = 1;
      }
      final html = _page == 1 ? await client.fetchHomeHtml() : await client.fetchHomeHtmlPage(_page);
      final newPins = PinterestParser.parseHomeHtml(html);
      for (final p in newPins) {
        final key = p.canonicalUrl;
        if (_seenUrls.add(key)) {
          _pins.add(p);
        }
      }
      _page += 1;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
              onPressed: () => _loadMore(reset: true),
              child: const Text('Reload'),
            )
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 800 && !_loading) {
          _loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadMore(reset: true);
        },
        child: MasonryGridView.count(
          padding: const EdgeInsets.all(8),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: _pins.length,
          itemBuilder: (context, index) {
            final pin = _pins[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PinTile(pin: pin),
            );
          },
        ),
      ),
    );
  }
}
