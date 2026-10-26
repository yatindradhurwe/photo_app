import 'package:photo_manager/photo_manager.dart';

/// Represents a folder/album containing media items
class AlbumModel {
  final AssetPathEntity pathEntity;
  final String id;
  final String name;
  final int assetCount;

  AlbumModel({
    required this.pathEntity,
    required this.id,
    required this.name,
    required this.assetCount,
  });

  static Future<AlbumModel> fromPathEntity(AssetPathEntity entity) async {
    final count = await entity.assetCountAsync;
    return AlbumModel(
      pathEntity: entity,
      id: entity.id,
      name: entity.name,
      assetCount: count,
    );
  }
}
