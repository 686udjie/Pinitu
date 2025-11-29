// big thanks to https://github.com/imputnet/cobalt/blob/main/api/src/processing/services/pinterest.js

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/pin.dart';
import '../models/user_profile.dart';

class PinterestParser {
  static List<PinItem> parseHomeHtml(String html) {
    final unique = <String>{};
    final items = <PinItem>[];

    bool isLikelyAvatarUrl(String url) {
      // regex to find avatar urls
      final avatarSizePattern = RegExp(
        r"/(60x60|75x75|120x120|140x140|170x|280x280)_RS/",
      );
      return avatarSizePattern.hasMatch(url) ||
          url.contains('avatar') ||
          url.contains('profile') ||
          url.contains('userimage');
    }

    // Extract images using regex
    final imageMatches = imageRegex.allMatches(html);
    for (final match in imageMatches) {
      final link = match.group(1)!;
      if (link.endsWith('.jpg') || link.endsWith('.gif')) {
        final mediaUrl = link.contains('i.pinimg.com')
            ? link.replaceAllMapped(RegExp(r'/(\d+)x/'), (match) => '/736x/')
            : link;
        final pin = PinItem(
          id: link.hashCode.toString(),
          mediaUrl: mediaUrl,
          isVideo: false,
        );
        final canon = pin.canonicalUrl;
        if (unique.add(canon)) items.add(pin);
      }
    }

    // Extract videos using regex from the extractor
    final videoMatches = videoRegex.allMatches(html);
    for (final match in videoMatches) {
      final link = match.group(1)!;
      if (link.endsWith('.mp4')) {
        final pin = PinItem(
          id: link.hashCode.toString(),
          mediaUrl: link,
          isVideo: true,
        );
        final canon = pin.canonicalUrl;
        if (unique.add(canon)) items.add(pin);
      }
    }

    // Parse images from DOM, only from pin links
    final document = html_parser.parse(html);
    for (final a in document.getElementsByTagName('a')) {
      final href = a.attributes['href'] ?? '';
      if (!href.contains('/pin/')) continue;
      for (final img in a.getElementsByTagName('img')) {
        final src = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
        if (src.isEmpty) continue;
        if (!src.contains('i.pinimg.com')) continue;
        if (isLikelyAvatarUrl(src)) continue;
        final mediaUrl = src.contains('i.pinimg.com')
            ? src.replaceAllMapped(RegExp(r'/(\d+)x/'), (match) => '/736x/')
            : src;
        final pin = PinItem(
          id: src.hashCode.toString(),
          mediaUrl: mediaUrl,
          isVideo: false,
        );
        final canon = pin.canonicalUrl;
        if (unique.add(canon)) items.add(pin);
      }
    }

    return items;
  }

  static UserProfile? parseUserProfileFromHtml(String html) {
    // variable names
    String? username;
    String? fullName;
    String? bio;
    String? avatarUrl;

    String? matchFirst(RegExp pattern) {
      final m = pattern.firstMatch(html);
      if (m != null && m.groupCount >= 1) {
        return m.group(1);
      }
      return null;
    }

    // Username
    username =
        matchFirst(RegExp(r'"username"\s*:\s*"([^"]+)"')) ??
        matchFirst(RegExp(r'"user_name"\s*:\s*"([^"]+)"'));

    // Full name (nickname would work??)
    fullName =
        matchFirst(RegExp(r'"full_name"\s*:\s*"([^"]+)"')) ??
        matchFirst(RegExp(r'"fullName"\s*:\s*"([^"]+)"')) ??
        matchFirst(RegExp(r'"name"\s*:\s*"([^"]+)"'));

    // Bio
    bio =
        matchFirst(RegExp(r'"about"\s*:\s*"([^"]*)"')) ??
        matchFirst(RegExp(r'"bio"\s*:\s*"([^"]*)"'));

    // Avatar keys (i tried to make it robust, it works but idk if i had to add 6 options)
    avatarUrl =
        matchFirst(RegExp(r'"image_xlarge_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        matchFirst(RegExp(r'"image_large_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        matchFirst(RegExp(r'"image_medium_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        matchFirst(RegExp(r'"image_small_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        matchFirst(RegExp(r'"profile_image_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        matchFirst(RegExp(r'"image_url"\s*:\s*"(https?:[^"\\]+)"'));

    if (username == null || username.isEmpty) {
      return null;
    }

    return UserProfile(
      username: username,
      fullName: (fullName == null || fullName.isEmpty) ? null : fullName,
      bio: (bio == null || bio.isEmpty) ? null : bio,
      avatarUrl: (avatarUrl == null || avatarUrl.isEmpty) ? null : avatarUrl,
    );
  }

  static final videoRegex = RegExp(
    r'"url":"(https://v1\.pinimg\.com/videos/.*?)"',
  );
  static final imageRegex = RegExp(
    r'src="(https://i\.pinimg\.com/.*\.(jpg|gif))"',
  );
  static final notFoundRegex = RegExp(r'"__typename"\s*:\s*"PinNotFound"');
  static const String genericUserAgent = 'Mozilla/5.0 (compatible; Pinitu/1.0)';

  static Future<Map<String, dynamic>?> resolveRedirectingURL(String url) async {
    final dio = Dio();
    try {
      final response = await dio.get(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 400,
        ),
      );
      final finalUrl = response.realUri.toString();
      final match = RegExp(r'/pin/(\d+)').firstMatch(finalUrl);
      if (match != null) {
        return {'id': match.group(1)};
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  static Future<Map<String, dynamic>> parsePin(Map<String, dynamic> o) async {
    String? id = o['id'];
    if (id == null && o['shortLink'] != null) {
      final patternMatch = await resolveRedirectingURL(
        'https://api.pinterest.com/url_shortener/${o['shortLink']}/redirect/',
      );
      id = patternMatch?['id'];
    }
    if (id != null && id.contains('--')) id = id.split('--')[1];
    if (id == null) return {'error': 'fetch.fail'};
    final dio = Dio();
    String? html;
    try {
      final response = await dio.get(
        'https://www.pinterest.com/pin/$id/',
        options: Options(headers: {'user-agent': genericUserAgent}),
      );
      html = response.data;
    } catch (e) {
      // ignore
    }
    if (html == null) return {'error': 'fetch.fail'};
    final invalidPin = notFoundRegex.hasMatch(html);
    if (invalidPin) return {'error': 'fetch.empty'};
    final videoMatches = videoRegex.allMatches(html);
    String? videoLink;
    for (final match in videoMatches) {
      final link = match.group(1)!;
      if (link.endsWith('.mp4')) {
        videoLink = link;
        break;
      }
    }
    if (videoLink != null) {
      return {
        'urls': videoLink,
        'filename': 'pinterest_$id.mp4',
        'audioFilename': 'pinterest_${id}_audio',
      };
    }
    final imageMatches = imageRegex.allMatches(html);
    String? imageLink;
    for (final match in imageMatches) {
      final link = match.group(1)!;
      if (link.endsWith('.jpg') || link.endsWith('.gif')) {
        imageLink = link;
        break;
      }
    }
    if (imageLink != null) {
      final imageType = imageLink.endsWith('.gif') ? 'gif' : 'jpg';
      return {
        'urls': imageLink,
        'isPhoto': true,
        'filename': 'pinterest_$id.$imageType',
      };
    }
    return {'error': 'fetch.empty'};
  }
}
