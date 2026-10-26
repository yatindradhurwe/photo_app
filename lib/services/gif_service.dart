import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/media_item.dart';
import 'media_service.dart';

/// Service to create animated GIFs from multiple selected photos
class GifService {
  /// Create animated GIF from a list of MediaItems
  /// [delayMs]: duration per frame in milliseconds (default 400ms)
  static Future<MediaItem?> createGifFromPhotos({
    required List<MediaItem> items,
    int delayMs = 400,
    int maxDimension = 500,
  }) async {
    if (items.length < 2) return null;

    try {
      final encoder = img.GifEncoder(
        delay: delayMs ~/ 10, // delay in 1/100 seconds
        repeat: 0,            // 0 = loop indefinitely
      );

      for (final item in items) {
        final File? file = await item.asset.file;
        if (file == null) continue;

        final Uint8List bytes = await file.readAsBytes();
        img.Image? decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        // Resize frame to maxDimension to maintain fast rendering and small file size
        if (decoded.width > maxDimension || decoded.height > maxDimension) {
          if (decoded.width >= decoded.height) {
            decoded = img.copyResize(decoded, width: maxDimension);
          } else {
            decoded = img.copyResize(decoded, height: maxDimension);
          }
        }

        encoder.addFrame(decoded, duration: delayMs ~/ 10);
      }

      final Uint8List? gifBytes = encoder.finish();
      if (gifBytes == null || gifBytes.isEmpty) return null;

      final String fileName = "PhotoApp_GIF_${DateTime.now().millisecondsSinceEpoch}.gif";

      final savedAsset = await MediaService.saveImage(
        imageBytes: gifBytes,
        title: fileName,
        description: 'Animated GIF created with PhotoApp',
      );

      if (savedAsset != null) {
        return MediaItem.fromAsset(savedAsset);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
