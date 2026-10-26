import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../widgets/media_thumbnail.dart';
import 'media_viewer_screen.dart';

class HiddenFolderScreen extends StatefulWidget {
  const HiddenFolderScreen({super.key});

  @override
  State<HiddenFolderScreen> createState() => _HiddenFolderScreenState();
}

class _HiddenFolderScreenState extends State<HiddenFolderScreen> {
  final Set<String> _selectedHidden = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedHidden.contains(id)) {
        _selectedHidden.remove(id);
        if (_selectedHidden.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedHidden.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<String> allIds) {
    setState(() {
      _selectedHidden.clear();
      _selectedHidden.addAll(allIds);
      _isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedHidden.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryProvider>(
      builder: (context, provider, child) {
        final hiddenItems = provider.hiddenMedia;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isSelectionMode
                  ? '${_selectedHidden.length} selected'
                  : 'Hidden Folder',
            ),
            actions: [
              if (_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select all',
                  onPressed: () => _selectAll(hiddenItems.map((e) => e.id).toList()),
                ),
                IconButton(
                  icon: const Icon(Icons.lock_open, color: Colors.blueAccent),
                  tooltip: 'Restore to Gallery',
                  onPressed: () async {
                    final ids = _selectedHidden.toList();
                    await provider.unhideItems(ids);
                    _clearSelection();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Restored ${ids.length} items to public gallery')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete permanently',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete from Device'),
                        content: Text('Permanently delete ${_selectedHidden.length} items?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final ids = _selectedHidden.toList();
                              for (final id in ids) {
                                await provider.deleteSingleItem(id);
                              }
                              await provider.unhideItems(ids);
                              _clearSelection();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Items deleted')),
                                );
                              }
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else if (hiddenItems.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: 'Select items',
                  onPressed: () => setState(() => _isSelectionMode = true),
                ),
              ],
            ],
          ),
          body: hiddenItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Hidden Folder is Empty',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'You can hide any photo or video from your timeline by opening it and selecting "Hide to Private Folder" or using the selection menu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.amber.withOpacity(0.12),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.amber, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'These ${hiddenItems.length} items are hidden from your main gallery.',
                              style: const TextStyle(fontSize: 12, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: hiddenItems.length,
                        itemBuilder: (context, index) {
                          final item = hiddenItems[index];
                          final isSelected = _selectedHidden.contains(item.id);

                          return MediaThumbnail(
                            item: item,
                            isSelected: isSelected,
                            selectionMode: _isSelectionMode,
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(item.id);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MediaViewerScreen(
                                      mediaItems: hiddenItems,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              _toggleSelection(item.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: _isSelectionMode
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ids = _selectedHidden.toList();
                            await provider.unhideItems(ids);
                            _clearSelection();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Restored ${ids.length} items to public gallery')),
                              );
                            }
                          },
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Unhide / Restore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearSelection,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
