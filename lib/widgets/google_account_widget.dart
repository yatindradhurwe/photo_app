import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/google_drive_provider.dart';

/// Widget to display Google account connection status and actions
class GoogleAccountWidget extends StatelessWidget {
  const GoogleAccountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoogleDriveProvider>(
      builder: (context, provider, child) {
        if (provider.isSignedIn) {
          return _buildSignedInView(context, provider);
        }
        return _buildSignInButton(context, provider);
      },
    );
  }

  Widget _buildSignedInView(BuildContext context, GoogleDriveProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: provider.userPhotoUrl != null
                      ? NetworkImage(provider.userPhotoUrl!)
                      : null,
                  child: provider.userPhotoUrl == null
                      ? Text(
                          provider.userDisplayName.isNotEmpty
                              ? provider.userDisplayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.userDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        provider.userEmail,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showSignOutDialog(context, provider),
                  tooltip: 'Sign out',
                ),
              ],
            ),
            if (provider.uploadStatus == UploadStatus.uploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: provider.uploadProgress,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading ${provider.completedUploads}/${provider.totalUploads}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
            if (provider.uploadStatus == UploadStatus.success) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Upload complete!',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  TextButton(
                    onPressed: provider.resetUploadStatus,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
            if (provider.uploadStatus == UploadStatus.error) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.uploadError ?? 'Upload failed',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: provider.resetUploadStatus,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context, GoogleDriveProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => provider.signIn(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect Google Drive',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upload and backup your photos & videos',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, GoogleDriveProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content:
            const Text('Are you sure you want to disconnect from Google Drive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.signOut();
              Navigator.pop(context);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
