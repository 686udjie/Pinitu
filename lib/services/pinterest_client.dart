import 'package:dio/dio.dart';

import 'cookie_store.dart';

class PinterestClient {
  final Dio _dio;

  PinterestClient._(this._dio);

  static Future<PinterestClient?> create() async {
    final cookieHeader = await CookieStore.buildCookieHeader();
    if (cookieHeader == null) return null;
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://www.pinterest.com',
        headers: {
          // TO DO?? add fall backs useragents if one fails
          'Cookie': cookieHeader,
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        responseType: ResponseType.plain,
        followRedirects: true,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );
    return PinterestClient._(dio);
  }

  Future<String> fetchHomeHtml() async {
    final res = await _dio.get<String>('/');
    return res.data ?? '';
  }

  Future<String> fetchHomeHtmlPage(int page) async {
    // Add a cache lobotomy query
    final ts = DateTime.now().millisecondsSinceEpoch;
    final res = await _dio.get<String>(
      '/',
      queryParameters: {
        '_cb': ts.toString(),
        'page': page.toString(),
      },
      options: Options(headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }),
    );
    return res.data ?? '';
  }
}
