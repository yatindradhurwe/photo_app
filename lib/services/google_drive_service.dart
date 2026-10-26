import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Authenticated HTTP client for Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/// Service to handle Google Sign-In and Drive uploads
class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  static GoogleSignInAccount? _currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => _currentUser != null;
  static GoogleSignInAccount? get currentUser => _currentUser;

  /// Sign in with Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Try silent sign in
  static Future<GoogleSignInAccount?> silentSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Get the Drive API instance
  static Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) return null;

    final authHeaders = await _currentUser!.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  /// Upload a file to Google Drive
  static Future<drive.File?> uploadFile({
    required File file,
    required String fileName,
    String? mimeType,
    Function(int, int)? onProgress,
  }) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    try {
      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['root'];

      final fileLength = await file.length();
      final media = drive.Media(
        file.openRead(),
        fileLength,
        contentType: mimeType ?? 'application/octet-stream',
      );

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      return result;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  /// Create a folder in Google Drive
  static Future<drive.File?> createFolder(String folderName) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    try {
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      return await driveApi.files.create(folder);
    } catch (e) {
      print('Create folder error: $e');
      return null;
    }
  }

  /// Upload file to a specific folder
  static Future<drive.File?> uploadToFolder({
    required File file,
    required String fileName,
    required String folderId,
    String? mimeType,
  }) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    try {
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final fileLength = await file.length();
      final media = drive.Media(
        file.openRead(),
        fileLength,
        contentType: mimeType ?? 'application/octet-stream',
      );

      return await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
    } catch (e) {
      print('Upload to folder error: $e');
      return null;
    }
  }

  /// Get or create PhotoApp folder
  static Future<String?> getOrCreatePhotoAppFolder() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    try {
      // Search for existing folder
      final fileList = await driveApi.files.list(
        q: "name = 'PhotoApp Uploads' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      // Create new folder
      final folder = await createFolder('PhotoApp Uploads');
      return folder?.id;
    } catch (e) {
      print('Get/create folder error: $e');
      return null;
    }
  }
}
