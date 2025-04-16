import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:device_apps/device_apps.dart';

class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen> {
  List<Application> _apps = [];
  List<Application> _filteredApps = [];
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
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
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
          return a.appName.compareTo(b.appName);
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
    if (_searchQuery.isEmpty) {
      _filteredApps = List.from(_apps);
    } else {
      _filteredApps =
          _apps.where((app) {
            final appName = app.appName.toLowerCase();
            final packageName = app.packageName.toLowerCase();
            final query = _searchQuery.toLowerCase();
            return appName.contains(query) || packageName.contains(query);
          }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Apps')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterApps();
                });
              },
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index] as ApplicationWithIcon;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: MemoryImage(app.icon),
                            backgroundColor: Colors.transparent,
                          ),
                          title: Text(app.appName),
                          subtitle: Text(app.packageName),
                          trailing: Consumer<NotificationProvider>(
                            builder: (context, provider, child) {
                              return FutureBuilder<bool>(
                                future: provider.isAppExcluded(app.packageName),
                                builder: (context, snapshot) {
                                  final isExcluded = snapshot.data ?? false;
                                  return Switch(
                                    value: !isExcluded,
                                    onChanged: (value) async {
                                      if (value) {
                                        await provider.includeApp(
                                          app.packageName,
                                        );
                                      } else {
                                        await provider.excludeApp(
                                          app.packageName,
                                        );
                                      }
                                      setState(() => _filterApps());
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
