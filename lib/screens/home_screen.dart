import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../providers/google_drive_provider.dart';
import '../widgets/media_thumbnail.dart';
import '../widgets/google_account_widget.dart';
import '../services/share_service.dart';
import 'album_screen.dart';
import 'media_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().initialize();
      context.read<GoogleDriveProvider>().initialize();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      context.read<GalleryProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildPhotosTab(),
          const AlbumScreen(),
          _buildCloudTab(),
        ],
      ),
      bottomNavigationBar: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          if (provider.isSelectionMode) {
            return _buildSelectionBar(provider);
          }
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.photo_library_outlined),
                selectedIcon: Icon(Icons.photo_library),
                label: 'Photos',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Albums',
              ),
              NavigationDestination(
                icon: Icon(Icons.cloud_outlined),
                selectedIcon: Icon(Icons.cloud),
                label: 'Cloud',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotosTab() {
    return Consumer<GalleryProvider>(
      builder: (context, provider, child) {
        return NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                snap: true,
                title: provider.isSelectionMode
                    ? Text('${provider.selectedItems.length} selected')
                    : const Text('Photos'),
                leading: provider.isSelectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: provider.clearSelection,
                      )
                    : null,
                actions: [
                  if (provider.isSelectionMode) ...[
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: provider.selectAll,
                      tooltip: 'Select all',
                    ),
                  ],
                ],
                bottom: provider.isSelectionMode
                    ? null
                    : PreferredSize(
                        preferredSize: const Size.fromHeight(50),
                        child: _buildFilterChips(provider),
                      ),
              ),
            ];
          },
          body: _buildMediaGrid(provider),
        );
      },
    );
  }

  Widget _buildFilterChips(GalleryProvider provider) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: 'All',
            isSelected: provider.viewMode == GalleryViewMode.all,
            onSelected: () => provider.setViewMode(GalleryViewMode.all),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Photos',
            isSelected: provider.viewMode == GalleryViewMode.photos,
            onSelected: () => provider.setViewMode(GalleryViewMode.photos),
            icon: Icons.image_outlined,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Videos',
            isSelected: provider.viewMode == GalleryViewMode.videos,
            onSelected: () => provider.setViewMode(GalleryViewMode.videos),
            icon: Icons.videocam_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  Widget _buildMediaGrid(GalleryProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!provider.hasPermission) {
      return _buildPermissionView(provider);
    }

    final media = provider.filteredMedia;

    if (media.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No media found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: media.length + (provider.isLoadingMore ? 3 : 0),
        itemBuilder: (context, index) {
          if (index >= media.length) {
            return Container(
              color: Theme.of(context).cardColor,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final item = media[index];
          return MediaThumbnail(
            item: item,
            isSelected: provider.isItemSelected(item.id),
            selectionMode: provider.isSelectionMode,
            onTap: () {
              if (provider.isSelectionMode) {
                provider.toggleItemSelection(item.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaViewerScreen(
                      mediaItems: media,
                      initialIndex: index,
                    ),
                  ),
                );
              }
            },
            onLongPress: () {
              provider.toggleItemSelection(item.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildPermissionView(GalleryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            const Text(
              'Permission Required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'PhotoApp needs access to your photos and videos to display them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.initialize,
              icon: const Icon(Icons.lock_open),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(GalleryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                ShareService.shareMultipleMedia(provider.selectedMediaItems);
              },
            ),
            _buildActionButton(
              icon: Icons.cloud_upload,
              label: 'Upload',
              onTap: () {
                final driveProvider = context.read<GoogleDriveProvider>();
                if (driveProvider.isSignedIn) {
                  driveProvider.uploadMediaItems(provider.selectedMediaItems);
                  provider.clearSelection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Uploading to Google Drive...')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please connect Google Drive first'),
                    ),
                  );
                }
              },
            ),
            _buildActionButton(
              icon: Icons.close,
              label: 'Cancel',
              onTap: provider.clearSelection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Backup'),
      ),
      body: ListView(
        children: [
          const GoogleAccountWidget(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How Google Backup Works',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Connect your Google Account using the card above.\n'
                      '• Select photos or videos from the "Photos" or "Albums" tabs.\n'
                      '• Tap the "Upload" action in selection mode or the cloud icon in full view.\n'
                      '• Uploaded items will automatically be saved into your dedicated Google Drive "PhotoApp Uploads" folder.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'PhotoApp',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Developed by YJTechnoSoft',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
