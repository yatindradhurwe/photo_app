import 'package:photo_manager/photo_manager.dart';

/// Represents a media item (photo or video) from the device gallery
class MediaItem {
  final AssetEntity asset;
  final String id;
  final String? title;
  final DateTime createDateTime;
  final AssetType type;
  final int width;
  final int height;
  final Duration? duration;

  MediaItem({
    required this.asset,
    required this.id,
    this.title,
    required this.createDateTime,
    required this.type,
    required this.width,
    required this.height,
    this.duration,
  });

  factory MediaItem.fromAsset(AssetEntity asset) {
    return MediaItem(
      asset: asset,
      id: asset.id,
      title: asset.title,
      createDateTime: asset.createDateTime,
      type: asset.type,
      width: asset.width,
      height: asset.height,
      duration: asset.type == AssetType.video
          ? Duration(seconds: asset.duration)
          : null,
    );
  }

  bool get isVideo => type == AssetType.video;
  bool get isImage => type == AssetType.image;
}
