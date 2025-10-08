import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _selectedIndex = 0;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasCookies) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pinitu')),
        body: Center(
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
      );
    }

    // Show main app with bottom navigation
    final List<Widget> pages = [
      const FeedGrid(),
      const SearchPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _selectedIndex == 0 ? 'Home' : 'Search',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        toolbarHeight: 40,
        leading: null,
        automaticallyImplyLeading: false,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 10),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 14,
          unselectedFontSize: 14,
          iconSize: 24,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<PinItem> _searchResults = <PinItem>[];
  final Set<String> _seenUrls = <String>{};
  late PinterestClient _client;
  bool _loading = false;
  bool _initialized = false;
  bool _hasSearched = false;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = <String>[];

  @override
  void initState() {
    super.initState();
    _init();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('search_history') ?? [];
      _searchHistory.clear();
      _searchHistory.addAll(historyList);
      setState(() {});
    } catch (e) {
      _searchHistory.clear();
      setState(() {});
    }
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
    } catch (e) {}
  }

  void _addToSearchHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty && !_searchHistory.contains(trimmedQuery)) {
      _searchHistory.insert(0, trimmedQuery);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
      _saveSearchHistory();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty || _loading) return;
    
    // Add to search history immediately when Enter is pressed
    _addToSearchHistory(query);
    
    setState(() {
      _loading = true;
      _searchResults.clear();
      _seenUrls.clear();
      _hasSearched = true;
    });

    try {
      // Fetch search results from Pinterest
      final html = await _client.fetchSearchHtml(query);
      final newPins = PinterestParser.parseHomeHtml(html);
      
      for (final p in newPins) {
        final key = p.canonicalUrl;
        if (_seenUrls.add(key)) {
          _searchResults.add(p);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _clearSearchHistory() async {
    _searchHistory.clear();
    setState(() {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
    } catch (e) {}
  }

  void _removeFromHistory(String query) {
    _searchHistory.remove(query);
    setState(() {});
    _saveSearchHistory();
  }

  void _selectHistoryItem(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Pinterest...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchResults.clear();
                        _seenUrls.clear();
                        _hasSearched = false;
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onSubmitted: _performSearch,
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Clear History Button
        if (_searchHistory.isNotEmpty && !_hasSearched)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearSearchHistory,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear History'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        // Search History
        if (_searchHistory.isNotEmpty && !_hasSearched)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeFromHistory(query),
                    color: Colors.grey[600],
                  ),
                  onTap: () => _selectHistoryItem(query),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                );
              },
            ),
          ),
        // Search Results
        if (_hasSearched)
          Expanded(
            child: _buildSearchContent(),
          ),
      ],
    );
  }

  Widget _buildSearchContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pin = _searchResults[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PinTile(pin: pin),
        );
      },
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
