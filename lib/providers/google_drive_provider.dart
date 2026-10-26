import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_drive_service.dart';
import '../models/media_item.dart';

enum UploadStatus { idle, uploading, success, error }

/// Provider for Google Drive state
class GoogleDriveProvider extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  UploadStatus _uploadStatus = UploadStatus.idle;
  String? _uploadError;
  double _uploadProgress = 0.0;
  int _totalUploads = 0;
  int _completedUploads = 0;

  // Getters
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  UploadStatus get uploadStatus => _uploadStatus;
  String? get uploadError => _uploadError;
  double get uploadProgress => _uploadProgress;
  int get totalUploads => _totalUploads;
  int get completedUploads => _completedUploads;

  String get userDisplayName =>
      _currentUser?.displayName ?? _currentUser?.email ?? 'Unknown';
  String get userEmail => _currentUser?.email ?? '';
  String? get userPhotoUrl => _currentUser?.photoUrl;

  /// Initialize - try silent sign in
  Future<void> initialize() async {
    _currentUser = await GoogleDriveService.silentSignIn();
    notifyListeners();
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    _currentUser = await GoogleDriveService.signIn();
    notifyListeners();
    return _currentUser != null;
  }

  /// Sign out
  Future<void> signOut() async {
    await GoogleDriveService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Upload media items to Google Drive
  Future<void> uploadMediaItems(List<MediaItem> items) async {
    if (!isSignedIn) return;

    _uploadStatus = UploadStatus.uploading;
    _totalUploads = items.length;
    _completedUploads = 0;
    _uploadProgress = 0.0;
    _uploadError = null;
    notifyListeners();

    try {
      // Get or create upload folder
      final folderId = await GoogleDriveService.getOrCreatePhotoAppFolder();

      for (final item in items) {
        final file = await item.asset.file;
        if (file == null) continue;

        final mimeType = item.isVideo ? 'video/mp4' : 'image/jpeg';
        final fileName = item.title ?? 'photo_${item.id}';

        if (folderId != null) {
          await GoogleDriveService.uploadToFolder(
            file: file,
            fileName: fileName,
            folderId: folderId,
            mimeType: mimeType,
          );
        } else {
          await GoogleDriveService.uploadFile(
            file: file,
            fileName: fileName,
            mimeType: mimeType,
          );
        }

        _completedUploads++;
        _uploadProgress = _completedUploads / _totalUploads;
        notifyListeners();
      }

      _uploadStatus = UploadStatus.success;
    } catch (e) {
      _uploadStatus = UploadStatus.error;
      _uploadError = e.toString();
    }
    notifyListeners();
  }

  /// Reset upload status
  void resetUploadStatus() {
    _uploadStatus = UploadStatus.idle;
    _uploadProgress = 0.0;
    _totalUploads = 0;
    _completedUploads = 0;
    _uploadError = null;
    notifyListeners();
  }
}
