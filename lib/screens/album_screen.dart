import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../widgets/album_card.dart';
import '../widgets/media_thumbnail.dart';
import 'media_viewer_screen.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.albums.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.selectedAlbum != null) {
          return _buildAlbumDetailView(context, provider);
        }

        return _buildAlbumsGrid(context, provider);
      },
    );
  }

  Widget _buildAlbumsGrid(BuildContext context, GalleryProvider provider) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
      ),
      body: provider.albums.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_outlined,
                      size: 80, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No albums found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: provider.refresh,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: provider.albums.length,
                itemBuilder: (context, index) {
                  final album = provider.albums[index];
                  return AlbumCard(
                    album: album,
                    onTap: () => provider.selectAlbum(album),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildAlbumDetailView(
      BuildContext context, GalleryProvider provider) {
    final media = provider.allMedia;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => provider.selectAlbum(null),
        ),
        title: Text(provider.selectedAlbum!.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${provider.selectedAlbum!.assetCount} items',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : media.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_outlined,
                          size: 80, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'This album is empty',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 500) {
                      provider.loadMore();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount:
                        media.length + (provider.isLoadingMore ? 3 : 0),
                    itemBuilder: (context, index) {
                      if (index >= media.length) {
                        return Container(
                          color: Theme.of(context).cardColor,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
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
                ),
    );
  }
}
