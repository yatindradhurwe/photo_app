import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/media_item.dart';
import '../models/album_model.dart';
import '../services/media_service.dart';

enum GalleryViewMode { all, photos, videos }

/// Provider for gallery state management
class GalleryProvider extends ChangeNotifier {
  // State
  List<MediaItem> _allMedia = [];
  List<AlbumModel> _albums = [];
  AlbumModel? _selectedAlbum;
  GalleryViewMode _viewMode = GalleryViewMode.all;
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  bool _hasMore = true;
  final int _pageSize = 80;
  Set<String> _selectedItems = {};
  bool _isSelectionMode = false;

  // Getters
  List<MediaItem> get allMedia => _allMedia;
  List<AlbumModel> get albums => _albums;
  AlbumModel? get selectedAlbum => _selectedAlbum;
  GalleryViewMode get viewMode => _viewMode;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  Set<String> get selectedItems => _selectedItems;
  bool get isSelectionMode => _isSelectionMode;

  List<MediaItem> get filteredMedia {
    switch (_viewMode) {
      case GalleryViewMode.photos:
        return _allMedia.where((item) => item.isImage).toList();
      case GalleryViewMode.videos:
        return _allMedia.where((item) => item.isVideo).toList();
      case GalleryViewMode.all:
        return _allMedia;
    }
  }

  List<MediaItem> get selectedMediaItems {
    return _allMedia.where((item) => _selectedItems.contains(item.id)).toList();
  }

  /// Initialize - request permission and load media
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _hasPermission = await MediaService.requestPermission();
    if (_hasPermission) {
      await Future.wait([
        _loadMedia(),
        _loadAlbums(),
      ]);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load media items
  Future<void> _loadMedia() async {
    RequestType type;
    switch (_viewMode) {
      case GalleryViewMode.photos:
        type = RequestType.image;
        break;
      case GalleryViewMode.videos:
        type = RequestType.video;
        break;
      case GalleryViewMode.all:
        type = RequestType.common;
        break;
    }

    if (_selectedAlbum != null) {
      _allMedia = await MediaService.getMediaFromAlbum(
        _selectedAlbum!.pathEntity,
        page: 0,
        pageSize: _pageSize,
      );
    } else {
      _allMedia = await MediaService.getAllMedia(
        page: 0,
        pageSize: _pageSize,
        type: type,
      );
    }
    _currentPage = 0;
    _hasMore = _allMedia.length >= _pageSize;
  }

  /// Load more media items (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;

    List<MediaItem> moreMedia;
    if (_selectedAlbum != null) {
      moreMedia = await MediaService.getMediaFromAlbum(
        _selectedAlbum!.pathEntity,
        page: _currentPage,
        pageSize: _pageSize,
      );
    } else {
      RequestType type;
      switch (_viewMode) {
        case GalleryViewMode.photos:
          type = RequestType.image;
          break;
        case GalleryViewMode.videos:
          type = RequestType.video;
          break;
        case GalleryViewMode.all:
          type = RequestType.common;
          break;
      }
      moreMedia = await MediaService.getAllMedia(
        page: _currentPage,
        pageSize: _pageSize,
        type: type,
      );
    }

    _allMedia.addAll(moreMedia);
    _hasMore = moreMedia.length >= _pageSize;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Load albums
  Future<void> _loadAlbums() async {
    _albums = await MediaService.getAlbums();
  }

  /// Refresh all data
  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadMedia(),
      _loadAlbums(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  /// Set view mode (all, photos, videos)
  Future<void> setViewMode(GalleryViewMode mode) async {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _selectedAlbum = null;
    _currentPage = 0;
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    await _loadMedia();
    _isLoading = false;
    notifyListeners();
  }

  /// Select a specific album
  Future<void> selectAlbum(AlbumModel? album) async {
    _selectedAlbum = album;
    _currentPage = 0;
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    await _loadMedia();
    _isLoading = false;
    notifyListeners();
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItems.clear();
    }
    notifyListeners();
  }

  /// Toggle item selection
  void toggleItemSelection(String id) {
    if (_selectedItems.contains(id)) {
      _selectedItems.remove(id);
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedItems.add(id);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  /// Select all items
  void selectAll() {
    _selectedItems = _allMedia.map((e) => e.id).toSet();
    _isSelectionMode = true;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedItems.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  bool isItemSelected(String id) => _selectedItems.contains(id);
}
