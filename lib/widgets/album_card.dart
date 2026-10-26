import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/album_model.dart';

/// Card widget for displaying an album/folder
class AlbumCard extends StatefulWidget {
  final AlbumModel album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  Uint8List? _coverThumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    try {
      final assets = await widget.album.pathEntity.getAssetListRange(
        start: 0,
        end: 1,
      );
      if (assets.isNotEmpty) {
        final data = await assets.first.thumbnailDataWithSize(
          const ThumbnailSize(400, 400),
          quality: 80,
        );
        if (mounted) {
          setState(() {
            _coverThumbnail = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isLoading
                  ? Container(
                      color: Theme.of(context).cardColor,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _coverThumbnail != null
                      ? Image.memory(
                          _coverThumbnail!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          gaplessPlayback: true,
                        )
                      : Container(
                          color: Theme.of(context).cardColor,
                          child: const Center(
                            child: Icon(Icons.photo_album_outlined, size: 40),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.album.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${widget.album.assetCount} items',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
