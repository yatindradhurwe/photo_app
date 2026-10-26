import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../providers/gallery_provider.dart';
import '../providers/google_drive_provider.dart';
import '../services/share_service.dart';
import '../utils/date_utils.dart';
import 'photo_editor_screen.dart';

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
  late List<MediaItem> _items;

  // View state: 0, 1, 2, 3 quarter turns
  int _viewerRotationTurns = 0;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.mediaItems);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  MediaItem get _currentItem => _items[_currentIndex];

  void _rotateCurrent() {
    setState(() {
      _viewerRotationTurns = (_viewerRotationTurns + 1) % 4;
    });
  }

  void _onDeletePressed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this file from your device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deleted = await context.read<GalleryProvider>().deleteSingleItem(_currentItem.id);
              if (deleted && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted successfully')),
                );
                setState(() {
                  _items.removeAt(_currentIndex);
                  if (_items.isEmpty) {
                    Navigator.pop(context);
                  } else {
                    if (_currentIndex >= _items.length) {
                      _currentIndex = _items.length - 1;
                    }
                  }
                });
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          children: [
            // Media viewer PageView with rotation
            RotatedBox(
              quarterTurns: _viewerRotationTurns,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _viewerRotationTurns = 0; // reset rotation on page change
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  if (item.isVideo) {
                    return _VideoPlayerWidget(
                      item: item,
                      showControls: _showControls,
                    );
                  }
                  return _ImageViewWidget(item: item);
                },
              ),
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
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                                  AppDateUtils.formatDate(_currentItem.createDateTime),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rotate button (Works for both Image & Video)
                          IconButton(
                            icon: const Icon(Icons.rotate_right, color: Colors.white),
                            tooltip: 'Rotate 90°',
                            onPressed: _rotateCurrent,
                          ),
                          // Edit Button for Photos
                          if (_currentItem.isImage)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.white),
                              tooltip: 'Edit & Crop',
                              onPressed: () async {
                                final edited = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhotoEditorScreen(mediaItem: _currentItem),
                                  ),
                                );
                                if (edited == true && mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          // Copy button
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            tooltip: 'Copy to Clipboard',
                            onPressed: () {
                              context.read<GalleryProvider>().copySingleItem(_currentItem);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard. Paste in Photos tab!')),
                              );
                            },
                          ),
                          // Hide button
                          IconButton(
                            icon: const Icon(Icons.lock_outline, color: Colors.white),
                            tooltip: 'Hide to Private Folder',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hide Media'),
                                  content: const Text(
                                    'Hide this item from your main gallery? You can view or restore it anytime from Albums > Hidden Folder.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await context.read<GalleryProvider>().hideSingleItem(_currentItem.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Item moved to Hidden Folder')),
                                          );
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text('Hide', style: TextStyle(color: Colors.amber)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            tooltip: 'Delete',
                            onPressed: _onDeletePressed,
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
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBottomAction(
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () => ShareService.shareMedia(_currentItem),
                          ),
                          _buildBottomAction(
                            icon: Icons.cloud_upload,
                            label: 'Upload',
                            onTap: () => _uploadToDrive(context),
                          ),
                          if (_currentItem.isImage)
                            _buildBottomAction(
                              icon: Icons.crop_rotate,
                              label: 'Edit',
                              onTap: () async {
                                final edited = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhotoEditorScreen(mediaItem: _currentItem),
                                  ),
                                );
                                if (edited == true && mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          _buildBottomAction(
                            icon: Icons.info_outline,
                            label: 'Info',
                            onTap: () => _showInfoSheet(context, _currentItem),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Page indicator badge
            if (_showControls && _items.length > 1)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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

/// Widget to display a single image with smooth double-tap, pinch-to-zoom and full screen
class _ImageViewWidget extends StatefulWidget {
  final MediaItem item;

  const _ImageViewWidget({required this.item});

  @override
  State<_ImageViewWidget> createState() => _ImageViewWidgetState();
}

class _ImageViewWidgetState extends State<_ImageViewWidget> {
  File? _file;
  Uint8List? _thumbnailData;
  late PhotoViewController _photoViewController;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
    _loadImage();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final thumb = await widget.item.asset.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
      quality: 90,
    );
    if (mounted) {
      setState(() => _thumbnailData = thumb);
    }

    final file = await widget.item.asset.file;
    if (mounted) {
      setState(() => _file = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_file != null) {
      return PhotoView(
        controller: _photoViewController,
        imageProvider: FileImage(_file!),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4.0,
        initialScale: PhotoViewComputedScale.contained,
        enableRotation: true,
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

/// Widget to play a video with Play/Pause, Speed Control (0.5x, 1.0x, 1.5x, 2.0x), Scrubber and Full Screen
class _VideoPlayerWidget extends StatefulWidget {
  final MediaItem item;
  final bool showControls;

  const _VideoPlayerWidget({
    required this.item,
    required this.showControls,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Uint8List? _thumbnailData;
  double _playbackSpeed = 1.0;

  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final thumb = await widget.item.asset.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
      quality: 90,
    );
    if (mounted) {
      setState(() => _thumbnailData = thumb);
    }

    final file = await widget.item.asset.file;
    if (file != null && mounted) {
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      if (_isPlaying != _controller!.value.isPlaying) {
        setState(() {
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
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

  void _changeSpeed(double speed) {
    if (_controller == null) return;
    _controller!.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Video viewport (Sized to fill available screen)
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

        // Center tap to Play/Pause
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _togglePlayPause,
          child: const SizedBox.expand(),
        ),

        // Big Center Play/Pause Indicator (shown when paused or when controls are toggled)
        if (_isInitialized && !_isPlaying)
          IgnorePointer(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 44),
            ),
          ),

        // Video overlay controls (Play/Pause, Speed selector, Scrubber)
        if (widget.showControls && _isInitialized && _controller != null)
          Positioned(
            bottom: 75,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Bar & Duration
                  Row(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _controller!,
                        builder: (context, VideoPlayerValue value, child) {
                          return Text(
                            AppDateUtils.formatDuration(value.position),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: VideoProgressColors(
                            playedColor: Theme.of(context).primaryColor,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppDateUtils.formatDuration(_controller!.value.duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Bottom Controls: Play/Pause button + Speed Control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _togglePlayPause,
                      ),

                      // Replay 10s button
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 24),
                        tooltip: 'Rewind 10s',
                        onPressed: () {
                          final current = _controller!.value.position;
                          final target = current - const Duration(seconds: 10);
                          _controller!.seekTo(target > Duration.zero ? target : Duration.zero);
                        },
                      ),

                      // Forward 10s button
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 24),
                        tooltip: 'Forward 10s',
                        onPressed: () {
                          final current = _controller!.value.position;
                          final max = _controller!.value.duration;
                          final target = current + const Duration(seconds: 10);
                          _controller!.seekTo(target < max ? target : max);
                        },
                      ),

                      // Speed Control Menu (0.5x, 1x, 1.5x, 2x)
                      PopupMenuButton<double>(
                        initialValue: _playbackSpeed,
                        tooltip: 'Playback Speed',
                        onSelected: _changeSpeed,
                        color: const Color(0xFF2C2C2C),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_playbackSpeed}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) {
                          return _speeds.map((s) {
                            return PopupMenuItem<double>(
                              value: s,
                              child: Text(
                                '${s}x',
                                style: TextStyle(
                                  color: s == _playbackSpeed ? Colors.blueAccent : Colors.white,
                                  fontWeight: s == _playbackSpeed ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
