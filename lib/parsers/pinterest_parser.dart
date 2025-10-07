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
      
      // Try to extract dimensions from various attributes
      int? width;
      int? height;
      
      // Check for width and height attributes
      final widthStr = img.attributes['width'];
      final heightStr = img.attributes['height'];
      
      if (widthStr != null && heightStr != null) {
        width = int.tryParse(widthStr);
        height = int.tryParse(heightStr);
      }
      
      // Check for style attribute with dimensions
      if (width == null || height == null) {
        final style = img.attributes['style'] ?? '';
        final widthMatch = RegExp(r'width:\s*(\d+)px').firstMatch(style);
        final heightMatch = RegExp(r'height:\s*(\d+)px').firstMatch(style);
        
        if (widthMatch != null) width = int.tryParse(widthMatch.group(1)!);
        if (heightMatch != null) height = int.tryParse(heightMatch.group(1)!);
      }
      
      // Check for data attributes that might contain dimensions
      if (width == null || height == null) {
        final dataWidth = img.attributes['data-width'];
        final dataHeight = img.attributes['data-height'];
        
        if (dataWidth != null) width = int.tryParse(dataWidth);
        if (dataHeight != null) height = int.tryParse(dataHeight);
      }
      
      final pin = PinItem(
        id: src.hashCode.toString(), 
        mediaUrl: src, 
        title: title, 
        isVideo: false,
        width: width,
        height: height,
      );
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
      
      // Try to extract video dimensions
      int? width;
      int? height;
      
      final widthStr = video.attributes['width'];
      final heightStr = video.attributes['height'];
      
      if (widthStr != null && heightStr != null) {
        width = int.tryParse(widthStr);
        height = int.tryParse(heightStr);
      }
      
      final pin = PinItem(
        id: src.hashCode.toString(), 
        mediaUrl: src, 
        isVideo: true,
        width: width,
        height: height,
      );
      final canon = pin.canonicalUrl;
      if (unique.add(canon)) {
        items.add(pin);
      }
    }

    return items;
  }
}
