import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../models/media_item.dart';
import '../models/album_model.dart';

/// Service to fetch and manage media from device storage
class MediaService {
  /// Request permission to access media
  static Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  /// Get all albums/folders
  static Future<List<AlbumModel>> getAlbums({
    RequestType type = RequestType.common,
  }) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    final models = await Future.wait(
      paths.map((e) => AlbumModel.fromPathEntity(e)),
    );
    return models;
  }

  /// Get media items from a specific album with pagination
  static Future<List<MediaItem>> getMediaFromAlbum(
    AssetPathEntity album, {
    int page = 0,
    int pageSize = 80,
  }) async {
    final List<AssetEntity> assets = await album.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    return assets.map((e) => MediaItem.fromAsset(e)).toList();
  }

  /// Get all media items with pagination
  static Future<List<MediaItem>> getAllMedia({
    int page = 0,
    int pageSize = 80,
    RequestType type = RequestType.common,
  }) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (paths.isEmpty) return [];

    // The first path with hasAll=true is "Recent" / "All"
    final allPath = paths.first;
    final List<AssetEntity> assets = await allPath.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    return assets.map((e) => MediaItem.fromAsset(e)).toList();
  }

  /// Delete a list of assets from device
  static Future<List<String>> deleteAssets(List<String> ids) async {
    try {
      final List<String> result = await PhotoManager.editor.deleteWithIds(ids);
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Save edited image to device storage
  static Future<AssetEntity?> saveImage({
    required List<int> imageBytes,
    required String title,
    String? description,
  }) async {
    try {
      final AssetEntity? entity = await PhotoManager.editor.saveImage(
        Uint8List.fromList(imageBytes),
        filename: title,
        title: title,
        desc: description ?? '',
      );
      return entity;
    } catch (e) {
      return null;
    }
  }
}
