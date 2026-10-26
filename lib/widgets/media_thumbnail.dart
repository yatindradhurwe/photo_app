import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/media_item.dart';
import '../utils/date_utils.dart';

/// A thumbnail widget for a media item
class MediaThumbnail extends StatefulWidget {
  final MediaItem item;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MediaThumbnail({
    super.key,
    required this.item,
    this.isSelected = false,
    this.selectionMode = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.item.asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
      quality: 80,
    );
    if (mounted) {
      setState(() {
        _thumbnailData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _isLoading || _thumbnailData == null
                ? Container(
                    color: Theme.of(context).cardColor,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Image.memory(
                    _thumbnailData!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
          ),

          // Video duration overlay
          if (widget.item.isVideo && widget.item.duration != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      AppDateUtils.formatDuration(widget.item.duration!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selection overlay
          if (widget.selectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),

          // Selected overlay tint
          if (widget.isSelected)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
