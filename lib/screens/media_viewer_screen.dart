import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../providers/google_drive_provider.dart';
import '../services/share_service.dart';
import '../utils/date_utils.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.mediaItems,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  MediaItem get _currentItem => widget.mediaItems[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          children: [
            // Media viewer
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaItems.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final item = widget.mediaItems[index];
                if (item.isVideo) {
                  return _VideoPlayerWidget(item: item);
                }
                return _ImageViewWidget(item: item);
              },
            ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentItem.title ?? 'Untitled',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  AppDateUtils.formatDate(
                                      _currentItem.createDateTime),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBottomAction(
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () =>
                                ShareService.shareMedia(_currentItem),
                          ),
                          _buildBottomAction(
                            icon: Icons.cloud_upload,
                            label: 'Upload',
                            onTap: () => _uploadToDrive(context),
                          ),
                          _buildBottomAction(
                            icon: Icons.info_outline,
                            label: 'Info',
                            onTap: () =>
                                _showInfoSheet(context, _currentItem),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Page indicator
            if (_showControls && widget.mediaItems.length > 1)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.mediaItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _uploadToDrive(BuildContext context) {
    final driveProvider = context.read<GoogleDriveProvider>();
    if (driveProvider.isSignedIn) {
      driveProvider.uploadMediaItems([_currentItem]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading to Google Drive...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connect Google Drive to upload'),
          action: SnackBarAction(
            label: 'Connect',
            onPressed: () => driveProvider.signIn(),
          ),
        ),
      );
    }
  }

  void _showInfoSheet(BuildContext context, MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.title, 'Name', item.title ?? 'Untitled'),
              _buildInfoRow(Icons.calendar_today, 'Date',
                  AppDateUtils.formatDate(item.createDateTime)),
              _buildInfoRow(Icons.aspect_ratio, 'Resolution',
                  '${item.width} × ${item.height}'),
              _buildInfoRow(Icons.category, 'Type',
                  item.isVideo ? 'Video' : 'Photo'),
              if (item.isVideo && item.duration != null)
                _buildInfoRow(Icons.timer, 'Duration',
                    AppDateUtils.formatDuration(item.duration!)),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display a single image with zoom
class _ImageViewWidget extends StatefulWidget {
  final MediaItem item;

  const _ImageViewWidget({required this.item});

  @override
  State<_ImageViewWidget> createState() => _ImageViewWidgetState();
}

class _ImageViewWidgetState extends State<_ImageViewWidget> {
  File? _file;
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    // Load thumbnail first for fast display
    final thumb = await widget.item.asset.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
      quality: 90,
    );
    if (mounted) {
      setState(() {
        _thumbnailData = thumb;
      });
    }

    // Then load full resolution
    final file = await widget.item.asset.file;
    if (mounted) {
      setState(() {
        _file = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_file != null) {
      return PhotoView(
        imageProvider: FileImage(_file!),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => Center(
          child: _thumbnailData != null
              ? Image.memory(_thumbnailData!, fit: BoxFit.contain)
              : const CircularProgressIndicator(),
        ),
      );
    }

    if (_thumbnailData != null) {
      return Center(
        child: Image.memory(_thumbnailData!, fit: BoxFit.contain),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}

/// Widget to play a video
class _VideoPlayerWidget extends StatefulWidget {
  final MediaItem item;

  const _VideoPlayerWidget({required this.item});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    // Load thumbnail
    final thumb = await widget.item.asset.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
      quality: 90,
    );
    if (mounted) {
      setState(() => _thumbnailData = thumb);
    }

    // Load video file
    final file = await widget.item.asset.file;
    if (file != null && mounted) {
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isInitialized && _controller != null)
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          )
        else if (_thumbnailData != null)
          Center(
            child: Image.memory(_thumbnailData!, fit: BoxFit.contain),
          )
        else
          const Center(child: CircularProgressIndicator()),

        // Play/Pause overlay
        if (_isInitialized && !_isPlaying)
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 40),
            ),
          ),
        if (_isInitialized && _isPlaying)
          GestureDetector(
            onTap: _togglePlayPause,
            child: const SizedBox.expand(),
          ),

        // Video progress
        if (_isInitialized && _controller != null)
          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
      ],
    );
  }
}
