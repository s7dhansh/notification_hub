import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Notification Listener Service'),
                subtitle: Text(provider.isListening ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: provider.isListening,
                  onChanged: (value) async {
                    if (value) {
                      await provider.startListening();
                    } else {
                      await provider.stopListening();
                    }
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('About'),
                subtitle: const Text('Notification Hub captures and organizes your notifications'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Notification Hub',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2023',
                    children: const [
                      SizedBox(height: 24),
                      Text(
                        'This app captures notifications from your device and hides them from the system. '
                        'Notifications will only appear in this app, grouped by individual apps.',
                      ),
                    ],
                  );
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                subtitle: const Text('How we handle your data'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Notification Hub captures your notifications to display them within the app. '
                          'No notification data is sent outside of your device. All data is stored locally '
                          'and is automatically cleared after a certain period to save space. '
                          '\n\nWe do not collect analytics or telemetry data.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Clear All Data'),
                subtitle: const Text('Remove all stored notifications'),
                onTap: () {
                  _confirmClearData(context, provider);
                },
              ),
              const Divider(),
              FutureBuilder<Set<String>>(
                future: provider.getExcludedApps(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final excludedApps = snapshot.data!;
                  
                  if (excludedApps.isEmpty) {
                    return ListTile(
                      title: const Text('Excluded Apps'),
                      subtitle: const Text('No apps are currently excluded'),
                    );
                  }
                  
                  return ExpansionTile(
                    title: const Text('Excluded Apps'),
                    subtitle: Text('${excludedApps.length} excluded apps'),
                    children: excludedApps.map((packageName) {
                      final appName = _getAppNameFromPackage(packageName);
                      return ListTile(
                        title: Text(appName),
                        subtitle: Text(packageName),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () async {
                            await provider.includeApp(packageName);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$appName will be tracked again'),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmClearData(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all stored notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get readable app name from package name
  String _getAppNameFromPackage(String packageName) {
    // Simple implementation similar to the one in NotificationService
    final parts = packageName.split('.');
    if (parts.isEmpty) return 'Unknown';
    return parts.last[0].toUpperCase() + parts.last.substring(1);
  }
}