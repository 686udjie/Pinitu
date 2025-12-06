class PinItem {
  final String id;
  final String mediaUrl;
  final String? title;
  final bool isVideo;
  final int? width;
  final int? height;
  final String? thumbnailUrl;
  final String? uploader;

  PinItem({
    required this.id,
    required this.mediaUrl,
    this.title,
    this.isVideo = false,
    this.width,
    this.height,
    this.thumbnailUrl,
    this.uploader,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaUrl': mediaUrl,
        'title': title,
        'isVideo': isVideo,
        'width': width,
        'height': height,
        'thumbnailUrl': thumbnailUrl,
        'uploader': uploader,
      };

  factory PinItem.fromJson(Map<String, dynamic> json) => PinItem(
        id: json['id'],
        mediaUrl: json['mediaUrl'],
        title: json['title'],
        isVideo: json['isVideo'],
        width: json['width'],
        height: json['height'],
        thumbnailUrl: json['thumbnailUrl'],
        uploader: json['uploader'],
      );

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
