import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../widgets/bottom_navigation_bar.dart';
import '../widgets/feed_grid.dart';
import '../widgets/saved_page.dart';
import '../widgets/search_page.dart';
import '../widgets/settings_page.dart';
import 'pinterest_login_webview_page.dart';

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
    _hasCookies = cookiesJson != null && cookiesJson.isNotEmpty;
    _loading = false;
    setState(() {});
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

    final List<Widget> pages = [
      const FeedGrid(),
      const SearchPage(),
      const SavedPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _selectedIndex == 0
                  ? 'Home'
                  : _selectedIndex == 1
                      ? 'Search'
                      : _selectedIndex == 2
                          ? 'Saved'
                          : 'Settings',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        toolbarHeight: 40,
        leading: null,
        automaticallyImplyLeading: false,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
