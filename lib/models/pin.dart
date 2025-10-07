class PinItem {
  final String id;
  final String mediaUrl;
  final String? title;
  final bool isVideo;

  PinItem({required this.id, required this.mediaUrl, this.title, this.isVideo = false});

  String get canonicalUrl {
    // Normalize to dedupe: strip query params and size segments if present.
    var url = mediaUrl.split('?').first;
    return url;
  }
}
