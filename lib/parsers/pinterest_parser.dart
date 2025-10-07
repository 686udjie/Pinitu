import 'package:collection/collection.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/pin.dart';

class PinterestParser {
  static List<PinItem> parseHomeHtml(String html) {
    final document = html_parser.parse(html);
    final unique = <String>{};
    final items = <PinItem>[];

    // Extract images
    for (final img in document.getElementsByTagName('img')) {
      final src = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
      if (src.isEmpty) continue;
      final title = img.attributes['alt'];
      final pin = PinItem(id: src.hashCode.toString(), mediaUrl: src, title: title, isVideo: false);
      final canon = pin.canonicalUrl;
      if (unique.add(canon)) {
        items.add(pin);
      }
    }

    // TO DO: add better logic for video extraction
    for (final video in document.getElementsByTagName('video')) {
      String? src = video.attributes['src'];
      if (src == null || src.isEmpty) {
        final sources = video.getElementsByTagName('source');
        src = sources.firstWhereOrNull((s) => (s.attributes['type'] ?? '').contains('video'))?.attributes['src'];
      }
      if (src == null || src.isEmpty) continue;
      final pin = PinItem(id: src.hashCode.toString(), mediaUrl: src, isVideo: true);
      final canon = pin.canonicalUrl;
      if (unique.add(canon)) {
        items.add(pin);
      }
    }

    return items;
  }
}
