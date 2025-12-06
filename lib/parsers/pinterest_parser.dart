// big thanks to https://github.com/imputnet/cobalt/blob/main/api/src/processing/services/pinterest.js

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/pin.dart';
import '../models/user_profile.dart';

class PinterestParser {
  static List<PinItem> parseHomeHtml(String html) {
    final unique = <String>{};
    final items = <PinItem>[];
    final pinPreferences = <String, bool>{};
    final document = html_parser.parse(html);


    String? extractPinId(String url) {
      final pinMatch = RegExp(r'/pin/(\d+)').firstMatch(url);
      if (pinMatch != null) return pinMatch.group(1);

      final mediaMatch = RegExp(r'pinimg\.com/[^/]+/[^/]+/([^/]+)').firstMatch(url);
      if (mediaMatch != null) return mediaMatch.group(1);

      return null;
    }

    bool isLikelyAvatarUrl(String url) {
      // regex to find avatar urls
      final avatarSizePattern = RegExp(r"_RS/");
      return avatarSizePattern.hasMatch(url) ||
          url.contains('avatar') ||
          url.contains('profile') ||
          url.contains('userimage');
    }

    // Extract videos using multiple regex patterns
    for (final videoRegex in videoRegexes) {
      final videoMatches = videoRegex.allMatches(html);
      for (final match in videoMatches) {
        String? pinId;
        String? link;

        // Handle different capture group arrangements
        if (match.groupCount >= 2) {
          // Patterns with both id and url
          if (videoRegex.pattern.contains('"id":"([^"]+)".*?"url":"')) {
            // id before url
            pinId = match.group(1);
            link = match.group(2);
          } else if (videoRegex.pattern.contains('"url":".*?"id":"')) {
            // url before id
            link = match.group(1);
            pinId = match.group(2);
          }
        } else if (match.groupCount >= 1) {
          // Patterns with just url
          link = match.group(1);
          pinId = extractPinId(link!) ?? link.hashCode.toString();
        }

        if (link != null && (link.endsWith('.mp4') || link.contains('.mp4'))) {
          final actualPinId = pinId ?? extractPinId(link) ?? link.hashCode.toString();
          pinPreferences[actualPinId] = true; // Prefer video for this pin

          // Try to extract dimensions from nearby JSON if available
          int? width, height;
          final videoContext = html.substring(
            match.start > 100 ? match.start - 100 : 0,
            match.end + 200 < html.length ? match.end + 200 : html.length,
          );

          final widthMatch = RegExp(r'"width"\s*:\s*(\d+)').firstMatch(videoContext);
          final heightMatch = RegExp(r'"height"\s*:\s*(\d+)').firstMatch(videoContext);

          if (widthMatch != null) width = int.tryParse(widthMatch.group(1)!);
          if (heightMatch != null) height = int.tryParse(heightMatch.group(1)!);

          final pin = PinItem(
            id: actualPinId,
            mediaUrl: link,
            isVideo: true,
            width: width,
            height: height,
          );
          if (unique.add(pin.id)) items.add(pin);
        }
      }
    }

    // Extract images using regex
    final imageMatches = imageRegex.allMatches(html);
    for (final match in imageMatches) {
      final link = match.group(1)!;
      if (isLikelyAvatarUrl(link)) continue;
      if (link.endsWith('.jpg') || link.endsWith('.gif')) {
        final pinId = extractPinId(link) ?? link.hashCode.toString();
        // Skip pin
        if (pinPreferences[pinId] == true) continue;

        final mediaUrl = link.contains('i.pinimg.com')
            ? link.replaceAllMapped(RegExp(r'/(\d+)x/'), (match) => '/736x/')
            : link;
        final pin = PinItem(
          id: pinId,
          mediaUrl: mediaUrl,
          isVideo: false,
        );
        if (unique.add(pin.id)) items.add(pin);
      }
    }

    // Parse images from DOM, only from pin links
    for (final a in document.getElementsByTagName('a')) {
      final href = a.attributes['href'] ?? '';
      if (!href.contains('/pin/')) continue;

      // Check for video elements
      for (final video in a.getElementsByTagName('video')) {
        final src = video.attributes['src'] ?? '';
        if (src.isNotEmpty && (src.endsWith('.mp4') || src.contains('.mp4'))) {
          final pinId = extractPinId(href) ?? extractPinId(src) ?? src.hashCode.toString();
          pinPreferences[pinId] = true;
          final width = int.tryParse(video.attributes['width'] ?? '');
          final height = int.tryParse(video.attributes['height'] ?? '');
          final thumbnailUrl = video.attributes['poster'];
          final pin = PinItem(
            id: pinId,
            mediaUrl: src,
            isVideo: true,
            width: width,
            height: height,
            thumbnailUrl: thumbnailUrl,
          );
          if (unique.add(pin.id)) items.add(pin);
        }
      }

      // Check for video sources within video tags
      for (final video in a.getElementsByTagName('video')) {
        for (final source in video.getElementsByTagName('source')) {
          final src = source.attributes['src'] ?? '';
          if (src.isNotEmpty && (src.endsWith('.mp4') || src.contains('.mp4'))) {
            final pinId = extractPinId(href) ?? extractPinId(src) ?? src.hashCode.toString();
            pinPreferences[pinId] = true;
            final width = int.tryParse(video.attributes['width'] ?? '');
            final height = int.tryParse(video.attributes['height'] ?? '');
            final thumbnailUrl = video.attributes['poster'];
            final pin = PinItem(
              id: pinId,
              mediaUrl: src,
              isVideo: true,
              width: width,
              height: height,
              thumbnailUrl: thumbnailUrl,
            );
            if (unique.add(pin.id)) items.add(pin);
          }
        }
      }

      for (final img in a.getElementsByTagName('img')) {
        final src = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
        if (src.isEmpty) continue;
        if (!src.contains('i.pinimg.com')) continue;
        if (isLikelyAvatarUrl(src)) continue;

        final pinId = extractPinId(href) ?? extractPinId(src) ?? src.hashCode.toString();
        // Skip pin
        if (pinPreferences[pinId] == true) continue;

        final width = int.tryParse(img.attributes['width'] ?? '');
        final height = int.tryParse(img.attributes['height'] ?? '');
        final mediaUrl = src.contains('i.pinimg.com')
            ? src.replaceAllMapped(RegExp(r'/(\d+)x/'), (match) => '/736x/')
            : src;
        final pin = PinItem(
          id: pinId,
          mediaUrl: mediaUrl,
          isVideo: false,
          width: width,
          height: height,
        );
        if (unique.add(pin.id)) items.add(pin);
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

  static final videoRegexes = [
    // Original pattern - id before url
    RegExp(r'"id":"([^"]+)".*?"url":"(https://[^"]*\.pinimg\.com/videos/[^"]*\.mp4[^"]*)"'),
    // Alternative pattern - url before id
    RegExp(r'"url":"(https://[^"]*\.pinimg\.com/videos/[^"]*\.mp4[^"]*)".*?"id":"([^"]+)"'),
    // More flexible pattern for any pinimg video URLs
    RegExp(r'"url":"(https://[^"]*\.pinimg\.com/videos/[^"]*\.mp4[^"]*)"'),
    // Pattern for v.pinimg.com domain
    RegExp(r'"url":"(https://v\.pinterest\.com/videos/[^"]*\.mp4[^"]*)"'),
    // Pattern for video URLs in different JSON structures
    RegExp(r'"video_url"\s*:\s*"([^"]*\.mp4[^"]*)"'),
    // Pattern for video URLs with escaped quotes
    RegExp(r'"url"\\?\s*:\\?\s*"([^"]*\.mp4[^"]*)"'),
  ];
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
    String? videoLink;
    for (final videoRegex in videoRegexes) {
      final videoMatches = videoRegex.allMatches(html);
      for (final match in videoMatches) {
        String? link;

        if (match.groupCount >= 2) {
          // Patterns with both id and url - get the url (group 2 for most patterns)
          if (videoRegex.pattern.contains('"id":"([^"]+)".*?"url":"')) {
            link = match.group(2);
          } else if (videoRegex.pattern.contains('"url":".*?"id":"')) {
            link = match.group(1);
          }
        } else if (match.groupCount >= 1) {
          // Patterns with just url
          link = match.group(1);
        }

        if (link != null && (link.endsWith('.mp4') || link.contains('.mp4'))) {
          videoLink = link;
          break;
        }
      }
      if (videoLink != null) break;
    }
    if (videoLink == null) {
      final document = html_parser.parse(html);
      for (final video in document.getElementsByTagName('video')) {
        final src = video.attributes['src'] ?? '';
        if (src.isNotEmpty && (src.endsWith('.mp4') || src.contains('.mp4'))) {
          videoLink = src;
          break;
        }
        for (final source in video.getElementsByTagName('source')) {
          final src = source.attributes['src'] ?? '';
          if (src.isNotEmpty && (src.endsWith('.mp4') || src.contains('.mp4'))) {
            videoLink = src;
            break;
          }
        }
        if (videoLink != null) break;
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
