import 'package:collection/collection.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/pin.dart';
import '../models/user_profile.dart';

class PinterestParser {
  static List<PinItem> parseHomeHtml(String html) {
    final document = html_parser.parse(html);
    final unique = <String>{};
    final items = <PinItem>[];

    bool _isLikelyAvatarUrl(String url) {
      // regex to find avatar urls
      final avatarSizePattern = RegExp(
        r"/(60x60|75x75|120x120|140x140|170x|280x280)_RS/",
      );
      return avatarSizePattern.hasMatch(url) ||
          url.contains('avatar') ||
          url.contains('profile') ||
          url.contains('userimage');
    }

    // this was added to differentiate from the avatar url. without this the avator would appear
    // in the homefeed. starting to notice this project is less about api usage but scraping their site
    // and all this code go booboo.
    bool _isLikelyPinImage(String url) {
      if (!url.startsWith('http')) return false;
      if (url.contains('s.pinimg.com')) return false;
      if (_isLikelyAvatarUrl(url)) return false;
      if (url.contains('i.pinimg.com')) return true;
      return url.contains('pinimg.com');
    }

    int? _tryParseInt(String? s) => s == null ? null : int.tryParse(s);

    void _extractDimensionsFromAttributes(
      Map<Object, String> attrs,
      void Function(int? w, int? h) setDims,
    ) {
      int? width;
      int? height;
      final widthStr = attrs['width'];
      final heightStr = attrs['height'];
      if (widthStr != null && heightStr != null) {
        width = _tryParseInt(widthStr);
        height = _tryParseInt(heightStr);
      }
      if (width == null || height == null) {
        final style = attrs['style'] ?? '';
        final widthMatch = RegExp(r'width:\s*(\d+)px').firstMatch(style);
        final heightMatch = RegExp(r'height:\s*(\d+)px').firstMatch(style);
        if (widthMatch != null) width = _tryParseInt(widthMatch.group(1));
        if (heightMatch != null) height = _tryParseInt(heightMatch.group(1));
      }
      if (width == null || height == null) {
        final dataWidth = attrs['data-width'];
        final dataHeight = attrs['data-height'];
        if (dataWidth != null) width = _tryParseInt(dataWidth);
        if (dataHeight != null) height = _tryParseInt(dataHeight);
      }
      setDims(width, height);
    }

    // im lazy so i js fetch all urls that have /pin/ in them
    // TODO: have actually proper logic
    for (final a in document.getElementsByTagName('a')) {
      final href = a.attributes['href'] ?? '';
      if (!href.contains('/pin/')) continue;

      String? pinId;
      final m = RegExp(r"/pin/(\d+)").firstMatch(href);
      if (m != null) pinId = m.group(1);

      // Looks for videos even tho videos dont work
      // TODO: add video support so this doesnt go to waste
      final videos = a.getElementsByTagName('video');
      if (videos.isNotEmpty) {
        for (final video in videos) {
          String? src = video.attributes['src'];
          if (src == null || src.isEmpty) {
            final sources = video.getElementsByTagName('source');
            src = sources
                .firstWhereOrNull(
                  (s) => (s.attributes['type'] ?? '').contains('video'),
                )
                ?.attributes['src'];
          }
          if (src == null || src.isEmpty) continue;
          int? w;
          int? h;
          _extractDimensionsFromAttributes(video.attributes, (x, y) {
            w = x;
            h = y;
          });
          final pin = PinItem(
            id: pinId ?? src.hashCode.toString(),
            mediaUrl: src,
            isVideo: true,
            width: w,
            height: h,
          );
          final canon = pin.canonicalUrl;
          if (unique.add(canon)) items.add(pin);
        }
      }

      // Then look for images inside the anchor
      final imgs = a.getElementsByTagName('img');
      for (final img in imgs) {
        final src = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
        if (src.isEmpty) continue;
        if (!_isLikelyPinImage(src)) continue;
        final title = img.attributes['alt'];
        int? w;
        int? h;
        _extractDimensionsFromAttributes(img.attributes, (x, y) {
          w = x;
          h = y;
        });
        final pin = PinItem(
          id: pinId ?? src.hashCode.toString(),
          mediaUrl: src,
          title: title,
          isVideo: false,
          width: w,
          height: h,
        );
        final canon = pin.canonicalUrl;
        if (unique.add(canon)) items.add(pin);
        break; // doesnt display the entire anchor, only the first image
      }
    }

    // fallback
    if (items.isEmpty) {
      // Images
      for (final img in document.getElementsByTagName('img')) {
        final src = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
        if (src.isEmpty) continue;
        if (!_isLikelyPinImage(src)) continue;
        final title = img.attributes['alt'];
        int? w;
        int? h;
        _extractDimensionsFromAttributes(img.attributes, (x, y) {
          w = x;
          h = y;
        });
        final pin = PinItem(
          id: src.hashCode.toString(),
          mediaUrl: src,
          title: title,
          isVideo: false,
          width: w,
          height: h,
        );
        final canon = pin.canonicalUrl;
        if (unique.add(canon)) items.add(pin);
      }

      // Videos
      // TODO: make it work
      for (final video in document.getElementsByTagName('video')) {
        String? src = video.attributes['src'];
        if (src == null || src.isEmpty) {
          final sources = video.getElementsByTagName('source');
          src = sources
              .firstWhereOrNull(
                (s) => (s.attributes['type'] ?? '').contains('video'),
              )
              ?.attributes['src'];
        }
        if (src == null || src.isEmpty) continue;
        int? w;
        int? h;
        _extractDimensionsFromAttributes(video.attributes, (x, y) {
          w = x;
          h = y;
        });
        final pin = PinItem(
          id: src.hashCode.toString(),
          mediaUrl: src,
          isVideo: true,
          width: w,
          height: h,
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

    String? _matchFirst(RegExp pattern) {
      final m = pattern.firstMatch(html);
      if (m != null && m.groupCount >= 1) {
        return m.group(1);
      }
      return null;
    }

    // Username
    username =
        _matchFirst(RegExp(r'"username"\s*:\s*"([^"]+)"')) ??
        _matchFirst(RegExp(r'"user_name"\s*:\s*"([^"]+)"'));

    // Full name (nickname would work??)
    fullName =
        _matchFirst(RegExp(r'"full_name"\s*:\s*"([^"]+)"')) ??
        _matchFirst(RegExp(r'"fullName"\s*:\s*"([^"]+)"')) ??
        _matchFirst(RegExp(r'"name"\s*:\s*"([^"]+)"'));

    // Bio
    bio =
        _matchFirst(RegExp(r'"about"\s*:\s*"([^"]*)"')) ??
        _matchFirst(RegExp(r'"bio"\s*:\s*"([^"]*)"'));

    // Avatar keys (i tried to make it robust, it works but idk if i had to add 6 options)
    avatarUrl =
        _matchFirst(RegExp(r'"image_xlarge_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        _matchFirst(RegExp(r'"image_large_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        _matchFirst(RegExp(r'"image_medium_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        _matchFirst(RegExp(r'"image_small_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        _matchFirst(RegExp(r'"profile_image_url"\s*:\s*"(https?:[^"\\]+)"')) ??
        _matchFirst(RegExp(r'"image_url"\s*:\s*"(https?:[^"\\]+)"'));

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
}
