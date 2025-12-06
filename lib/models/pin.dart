class PinItem {
  final String id;
  final String mediaUrl;
  final String? title;
  final bool isVideo;
  final int? width;
  final int? height;
  final String? thumbnailUrl;

  PinItem({
    required this.id,
    required this.mediaUrl,
    this.title,
    this.isVideo = false,
    this.width,
    this.height,
    this.thumbnailUrl,
  });

  String get canonicalUrl {
    // Normalize to dedupe: strip query params and size segments if present.
    var url = mediaUrl.split('?').first;
    return url;
  }

  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;
    return width! / height!;
  }
}
