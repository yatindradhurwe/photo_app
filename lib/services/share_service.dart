import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../models/media_item.dart';

/// Service to handle sharing media
class ShareService {
  /// Share a single media item
  static Future<void> shareMedia(MediaItem item) async {
    final file = await item.asset.file;
    if (file == null) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: item.title ?? 'Shared from PhotoApp',
    );
  }

  /// Share multiple media items
  static Future<void> shareMultipleMedia(List<MediaItem> items) async {
    final List<XFile> files = [];

    for (final item in items) {
      final file = await item.asset.file;
      if (file != null) {
        files.add(XFile(file.path));
      }
    }

    if (files.isEmpty) return;

    await Share.shareXFiles(
      files,
      text: 'Shared ${files.length} items from PhotoApp',
    );
  }

  /// Share a file directly
  static Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text ?? 'Shared from PhotoApp',
    );
  }
}
