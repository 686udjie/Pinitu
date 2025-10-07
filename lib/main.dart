// TO DO: rewrite this file and remove logout button at the bottom right

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'models/pin.dart';
import 'parsers/pinterest_parser.dart';
import 'services/pinterest_client.dart';
import 'widgets/pin_tile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PinituApp());
}

class PinituApp extends StatelessWidget {
  const PinituApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinitu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/login': (_) => const PinterestLoginWebViewPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _secureStorage = FlutterSecureStorage();
  bool _hasCookies = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCookieState();
  }

  Future<void> _loadCookieState() async {
    final cookiesJson = await _secureStorage.read(key: 'pinterest_cookies');
    setState(() {
      _hasCookies = cookiesJson != null && cookiesJson.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _handleLogin() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinterestLoginWebViewPage()),
    );
    if (loggedIn == true) {
      await _loadCookieState();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pinitu')),
      body: _hasCookies
          ? const FeedGrid()
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Log in with Pinterest to see your home feed',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Log in with Pinterest'),
                  ),
                ],
              ),
            ),
      floatingActionButton: _hasCookies
          ? FloatingActionButton.extended(
              onPressed: () async {
                await const FlutterSecureStorage().delete(key: 'pinterest_cookies');
                await CookieManager.instance().deleteAllCookies();
                if (mounted) {
                  setState(() {
                    _hasCookies = false;
                  });
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            )
          : null,
    );
  }
}

class FeedGrid extends StatefulWidget {
  const FeedGrid({super.key});

  @override
  State<FeedGrid> createState() => _FeedGridState();
}

class _FeedGridState extends State<FeedGrid> {
  final List<PinItem> _pins = <PinItem>[];
  final Set<String> _seenUrls = <String>{};
  late PinterestClient _client;
  bool _loading = false;
  bool _initialized = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final client = await PinterestClient.create();
    if (!mounted) return;
    if (client == null) {
      setState(() {
        _initialized = true;
      });
      return;
    }
    _client = client;
    setState(() {
      _initialized = true;
    });
    await _loadMore(reset: true);
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
      final html = _page == 1 ? await _client.fetchHomeHtml() : await _client.fetchHomeHtmlPage(_page);
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
    if (!_initialized) {
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

class PinterestLoginWebViewPage extends StatefulWidget {
  const PinterestLoginWebViewPage({super.key});

  @override
  State<PinterestLoginWebViewPage> createState() => _PinterestLoginWebViewPageState();
}

class _PinterestLoginWebViewPageState extends State<PinterestLoginWebViewPage> {
  static const _secureStorage = FlutterSecureStorage();
  late final InAppWebViewController _controller;
  bool _isLoggedIn = false;

  final Uri _loginUrl = Uri.parse('https://www.pinterest.com/login/');
  final Uri _rootUrl = Uri.parse('https://www.pinterest.com/');

  Future<void> _checkAndCaptureCookies(WebUri? url) async {
    if (url == null) return;

    final host = url.host;
    final path = url.path;

    if (host.contains('pinterest.com') && !path.startsWith('/login')) {
      final cookies = await CookieManager.instance().getCookies(url: WebUri(_rootUrl.toString()));
      if (cookies.isNotEmpty) {
        final encoded = jsonEncode(cookies
            .map((c) => {
                  'name': c.name,
                  'value': c.value,
                  'domain': c.domain,
                  'path': c.path,
                  'expiresDate': c.expiresDate,
                  'isSecure': c.isSecure,
                  'isHttpOnly': c.isHttpOnly,
                })
            .toList());
        await _secureStorage.write(key: 'pinterest_cookies', value: encoded);
        if (mounted && !_isLoggedIn) {
          setState(() {
            _isLoggedIn = true;
          });
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinterest Login')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_loginUrl.toString())),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          clearCache: false,
          thirdPartyCookiesEnabled: true,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onLoadStop: (controller, url) async {
          await _checkAndCaptureCookies(url);
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) async {
          await _checkAndCaptureCookies(url);
        },
      ),
    );
  }
}
