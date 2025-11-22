import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinterestLoginWebViewPage extends StatefulWidget {
  const PinterestLoginWebViewPage({super.key});

  @override
  State<PinterestLoginWebViewPage> createState() =>
      _PinterestLoginWebViewPageState();
}

class _PinterestLoginWebViewPageState extends State<PinterestLoginWebViewPage> {
  static const _secureStorage = FlutterSecureStorage();
  bool _isLoggedIn = false;

  final Uri _loginUrl = Uri.parse('https://www.pinterest.com/login/');
  final Uri _rootUrl = Uri.parse('https://www.pinterest.com/');

  Future<void> _checkAndCaptureCookies(WebUri? url) async {
    if (url == null) return;

    final host = url.host;
    final path = url.path;

    if (host.contains('pinterest.com') && !path.startsWith('/login')) {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(_rootUrl.toString()),
      );
      if (cookies.isNotEmpty) {
        final encoded = jsonEncode(
          cookies
              .map(
                (c) => {
                  'name': c.name,
                  'value': c.value,
                  'domain': c.domain,
                  'path': c.path,
                  'expiresDate': c.expiresDate,
                  'isSecure': c.isSecure,
                  'isHttpOnly': c.isHttpOnly,
                },
              )
              .toList(),
        );
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
          // Controller available if needed for future use
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
