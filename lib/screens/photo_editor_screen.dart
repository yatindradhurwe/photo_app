import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../providers/gallery_provider.dart';
import '../services/media_service.dart';

enum FilterPreset { none, grayscale, sepia, invert, vintage, cool, warm }

class PhotoEditorScreen extends StatefulWidget {
  final MediaItem mediaItem;

  const PhotoEditorScreen({super.key, required this.mediaItem});

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  File? _originalFile;
  Uint8List? _previewBytes;
  bool _isLoading = true;
  bool _isSaving = false;

  // Edit states
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3
  bool _flipHorizontal = false;
  bool _flipVertical = false;
  double _brightness = 0.0; // -100 to +100
  double _contrast = 0.0; // -100 to +100
  FilterPreset _selectedFilter = FilterPreset.none;

  // Crop ratios: null (free), 1.0 (1:1), 4/3, 16/9
  double? _cropAspectRatio;

  @override
  void initState() {
    super.initState();
    _loadOriginal();
  }

  Future<void> _loadOriginal() async {
    final file = await widget.mediaItem.asset.file;
    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      setState(() {
        _originalFile = file;
        _previewBytes = bytes;
        _isLoading = false;
      });
    }
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _flipH() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
  }

  void _flipV() {
    setState(() {
      _flipVertical = !_flipVertical;
    });
  }

  Future<void> _saveEditedPhoto() async {
    if (_originalFile == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final bytes = await _originalFile!.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      // 1. Rotate
      if (_rotationQuarterTurns == 1) {
        image = img.copyRotate(image, angle: 90);
      } else if (_rotationQuarterTurns == 2) {
        image = img.copyRotate(image, angle: 180);
      } else if (_rotationQuarterTurns == 3) {
        image = img.copyRotate(image, angle: 270);
      }

      // 2. Flip
      if (_flipHorizontal) {
        image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
      }
      if (_flipVertical) {
        image = img.copyFlip(image, direction: img.FlipDirection.vertical);
      }

      // 3. Aspect Crop
      if (_cropAspectRatio != null) {
        final w = image.width;
        final h = image.height;
        int targetW = w;
        int targetH = (w / _cropAspectRatio!).round();

        if (targetH > h) {
          targetH = h;
          targetW = (h * _cropAspectRatio!).round();
        }

        final x = (w - targetW) ~/ 2;
        final y = (h - targetH) ~/ 2;
        image = img.copyCrop(image, x: x, y: y, width: targetW, height: targetH);
      }

      // 4. Brightness & Contrast
      if (_brightness != 0.0) {
        // brightness: -100 to +100 -> range around 1.0
        final factor = 1.0 + (_brightness / 100.0);
        image = img.adjustColor(image, brightness: factor);
      }
      if (_contrast != 0.0) {
        final factor = 1.0 + (_contrast / 100.0);
        image = img.adjustColor(image, contrast: factor);
      }

      // 5. Presets
      switch (_selectedFilter) {
        case FilterPreset.grayscale:
          image = img.grayscale(image);
          break;
        case FilterPreset.sepia:
          image = img.sepia(image);
          break;
        case FilterPreset.invert:
          image = img.invert(image);
          break;
        case FilterPreset.vintage:
          image = img.sepia(image, amount: 0.6);
          image = img.adjustColor(image, contrast: 1.1, saturation: 0.8);
          break;
        case FilterPreset.cool:
          image = img.adjustColor(image, amount: 0.3);
          break;
        case FilterPreset.warm:
          image = img.adjustColor(image, gamma: 0.9);
          break;
        case FilterPreset.none:
          break;
      }

      final encoded = img.encodeJpg(image, quality: 92);
      final title = "Edited_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final savedAsset = await MediaService.saveImage(
        imageBytes: encoded,
        title: title,
      );

      if (mounted) {
        if (savedAsset != null) {
          context.read<GalleryProvider>().addMediaItem(MediaItem.fromAsset(savedAsset));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Edited photo saved to gallery!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save edited photo')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Photo'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveEditedPhoto,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, color: Colors.blueAccent),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Live preview area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildPreview(),
                    ),
                  ),
                ),

                // Editor tools panel
                _buildToolsPanel(),
              ],
            ),
    );
  }

  Widget _buildPreview() {
    Widget imageWidget = Image.memory(
      _previewBytes!,
      fit: BoxFit.contain,
    );

    // Apply aspect ratio container
    if (_cropAspectRatio != null) {
      imageWidget = AspectRatio(
        aspectRatio: _cropAspectRatio!,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: imageWidget,
          ),
        ),
      );
    }

    // Transformations
    Widget transformed = RotatedBox(
      quarterTurns: _rotationQuarterTurns,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _flipHorizontal ? -1.0 : 1.0,
          _flipVertical ? -1.0 : 1.0,
          1.0,
        ),
        child: imageWidget,
      ),
    );

    // Apply color filter simulation for preview
    ColorFilter? filter;
    switch (_selectedFilter) {
      case FilterPreset.grayscale:
        filter = const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
        break;
      case FilterPreset.sepia:
        filter = const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]);
        break;
      case FilterPreset.invert:
        filter = const ColorFilter.matrix(<double>[
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1, 0,
        ]);
        break;
      case FilterPreset.vintage:
        filter = const ColorFilter.matrix(<double>[
          0.9, 0.1, 0.1, 0, 15,
          0.1, 0.8, 0.1, 0, 10,
          0.1, 0.1, 0.7, 0, 5,
          0,   0,   0,   1, 0,
        ]);
        break;
      case FilterPreset.cool:
        filter = const ColorFilter.matrix(<double>[
          0.8, 0,   0,   0, 0,
          0,   0.9, 0,   0, 0,
          0,   0,   1.2, 0, 20,
          0,   0,   0,   1, 0,
        ]);
        break;
      case FilterPreset.warm:
        filter = const ColorFilter.matrix(<double>[
          1.2, 0,   0,   0, 20,
          0,   1.0, 0,   0, 10,
          0,   0,   0.8, 0, 0,
          0,   0,   0,   1, 0,
        ]);
        break;
      case FilterPreset.none:
        filter = null;
        break;
    }

    if (filter != null) {
      transformed = ColorFiltered(colorFilter: filter, child: transformed);
    }

    return transformed;
  }

  Widget _buildToolsPanel() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: DefaultTabController(
        length: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TabBar(
              indicatorColor: Colors.blueAccent,
              tabs: [
                Tab(icon: Icon(Icons.crop_rotate), text: 'Crop & Rotate'),
                Tab(icon: Icon(Icons.filter), text: 'Filters'),
                Tab(icon: Icon(Icons.tune), text: 'Adjust'),
              ],
            ),
            SizedBox(
              height: 120,
              child: TabBarView(
                children: [
                  _buildCropRotateTab(),
                  _buildFiltersTab(),
                  _buildAdjustTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropRotateTab() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildActionTile(
          icon: Icons.rotate_right,
          label: '90° Rotate',
          onTap: _rotateClockwise,
        ),
        _buildActionTile(
          icon: Icons.flip,
          label: 'Flip H',
          onTap: _flipH,
        ),
        _buildActionTile(
          icon: Icons.flip,
          label: 'Flip V',
          onTap: _flipV,
        ),
        const VerticalDivider(color: Colors.grey),
        _buildCropTile(label: 'Original', ratio: null),
        _buildCropTile(label: '1:1 Square', ratio: 1.0),
        _buildCropTile(label: '4:3', ratio: 4 / 3),
        _buildCropTile(label: '16:9', ratio: 16 / 9),
      ],
    );
  }

  Widget _buildCropTile({required String label, required double? ratio}) {
    final isSelected = _cropAspectRatio == ratio;
    return GestureDetector(
      onTap: () => setState(() => _cropAspectRatio = ratio),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersTab() {
    final presets = [
      {'preset': FilterPreset.none, 'name': 'Original'},
      {'preset': FilterPreset.grayscale, 'name': 'B&W'},
      {'preset': FilterPreset.sepia, 'name': 'Sepia'},
      {'preset': FilterPreset.vintage, 'name': 'Vintage'},
      {'preset': FilterPreset.cool, 'name': 'Cool'},
      {'preset': FilterPreset.warm, 'name': 'Warm'},
      {'preset': FilterPreset.invert, 'name': 'Invert'},
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final item = presets[index];
        final preset = item['preset'] as FilterPreset;
        final name = item['name'] as String;
        final isSelected = _selectedFilter == preset;

        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = preset),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdjustTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_6, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Brightness', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: _brightness,
                  min: -50,
                  max: 50,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => setState(() => _brightness = val),
                ),
              ),
              Text('${_brightness.round()}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.contrast, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Contrast', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: _contrast,
                  min: -50,
                  max: 50,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => setState(() => _contrast = val),
                ),
              ),
              Text('${_contrast.round()}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
