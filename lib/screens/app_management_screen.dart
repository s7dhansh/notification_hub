import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:installed_apps/installed_apps.dart'; // Changed import
import 'package:installed_apps/app_info.dart';

class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen> {
  List<AppInfo> _apps = []; // Changed type to AppInfo
  List<AppInfo> _filteredApps = []; // Changed type to AppInfo
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);

    try {
      // Load all installed apps
      final apps = await InstalledApps.getInstalledApps(
        true, // shouldReturnIcons
        false, // shouldReturnSystemApps
        '' // packageNamePrefix
      );

      // Load excluded status for all apps
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final excludedApps = await provider.getExcludedApps();

      setState(() {
        _apps = apps;
        // Sort apps - excluded first, then alphabetically by name
        _apps.sort((a, b) {
          final isAExcluded = excludedApps.contains(a.packageName);
          final isBExcluded = excludedApps.contains(b.packageName);
          if (isAExcluded != isBExcluded) {
            return isAExcluded ? -1 : 1;

          }
          return a.name.compareTo(b.name); // Changed appName to name and added null check
        });
        _filterApps();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterApps() {
    setState(() {
      _filteredApps = _apps
          .where((app) =>
              app.name.toLowerCase().contains(_searchQuery.toLowerCase()) || // Changed appName to name and added null check
              app.packageName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Apps'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _filterApps();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                    ? const Center(child: Text('No apps found.'))
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          return ListTile(
                            leading: app.icon != null ? Image.memory(app.icon!) : null, // Changed icon path
                            title: Text(app.name), // Changed appName to name and added null check
                            subtitle: Text(app.packageName),
                            // trailing: Consumer<NotificationProvider>(
                            //   builder: (context, provider, child) {
                            //     final isExcluded = provider.excludedApps.contains(app.packageName);
                            //     return Switch(
                            //       value: !isExcluded,
                            //       onChanged: (value) {
                            //         provider.toggleAppExcluded(app.packageName, !value);
                            //       },
                            //     );
                            //   },
                            // ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
