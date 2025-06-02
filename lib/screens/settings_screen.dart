import 'package:flutter/material.dart'
    show
        AlertDialog,
        Alignment,
        AppBar,
        BuildContext,
        Colors,
        Container,
        DismissDirection,
        Dismissible,
        Divider,
        EdgeInsets,
        ExpansionTile,
        FutureBuilder,
        Icon,
        Icons,
        State,
        ListTile,
        ListView,
        Navigator,
        Scaffold,
        ScaffoldMessenger,
        SingleChildScrollView,
        SizedBox,
        SnackBar,
        StatefulWidget,
        Switch,
        Text,
        TextButton,
        ValueKey,
        Widget,
        showAboutDialog,
        showDialog,
        DropdownButton,
        DropdownMenuItem,
        SwitchListTile,
        Column,
        CrossAxisAlignment,
        Image,
        ThemeMode;
import 'package:provider/provider.dart' show Consumer;
import 'package:notification_listener_service/notification_listener_service.dart'
    show NotificationListenerService;
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/notification_provider.dart' show NotificationProvider;
import '../services/notification_service.dart' show NotificationService;
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _removeSystemTrayNotification = true; // Default to no removal
  static const _removeSystemTrayKey = 'removeSystemTrayNotification';

  @override
  void initState() {
    super.initState();
    _loadSetting();
    _showLockTipIfFirstLaunch();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _removeSystemTrayNotification =
          prefs.getBool(_removeSystemTrayKey) ?? true; // Default to false
    });
  }

  Future<void> _saveSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_removeSystemTrayKey, value);
    // We will inform the native side later
  }

  Future<void> _saveHistoryDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('historyDays', days);
  }

  Future<int> _loadHistoryDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('historyDays') ?? 7;
  }

  Future<void> _showLockTipIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('shownLockTipDialog') ?? false;
    if (!shown && mounted) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Tip: Lock Notification Hub in Recents'),
              content: const Text(
                'For best reliability, lock Notification Hub in your recent apps list.\n'
                'On some devices (Xiaomi, Oppo, Vivo, etc.), swipe down on the app in recents and tap the lock icon.\n'
                'This prevents the system from killing the app in the background.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showOemScreenshots(context);
                  },
                  child: const Text('Show Examples'),
                ),
              ],
            ),
      );
      await prefs.setBool('shownLockTipDialog', true);
    }
  }

  void _showOemScreenshots(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('How to Lock in Recents'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Xiaomi/MIUI:'),
                  const SizedBox(height: 8),
                  Image.asset('assets/images/lock_xiaomi.png', height: 120),
                  const Text(
                    'Swipe down on the app in recents, tap the lock icon.',
                  ),
                  const Divider(),
                  const Text('Oppo/Vivo/Realme:'),
                  const SizedBox(height: 8),
                  Image.asset('assets/images/lock_oppo.png', height: 120),
                  const Text(
                    'Long-press the app in recents, tap the lock or padlock icon.',
                  ),
                  const Divider(),
                  const Text('Samsung/Pixel:'),
                  const SizedBox(height: 8),
                  Image.asset('assets/images/lock_samsung.png', height: 120),
                  const Text(
                    'No lock needed, but keep battery optimization disabled.',
                  ),
                ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              // Theme Mode Setting
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return ListTile(
                    title: const Text('Theme'),
                    subtitle: Text(_themeModeLabel(themeProvider.themeMode)),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          themeProvider.setThemeMode(mode);
                        }
                      },
                    ),
                  );
                },
              ),
              const Divider(),
              // Notification Listener Permission
              FutureBuilder<bool>(
                future: NotificationListenerService.isPermissionGranted(),
                builder: (context, snapshot) {
                  final hasPermission = snapshot.data ?? false;
                  return ListTile(
                    title: const Text('Notification Access Permission'),
                    subtitle: Text(
                      hasPermission
                          ? 'Granted - App can read notifications'
                          : 'Required - Tap to enable notification access',
                    ),
                    trailing:
                        hasPermission
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : const Icon(Icons.error, color: Colors.red),
                    onTap: () async {
                      if (!hasPermission) {
                        // Open system settings for notification access
                        await NotificationService().requestPermission();
                        // Show guidance to user
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enable Notification Hub in the list and return to the app',
                              ),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
              const Divider(),

              // Notification Service Toggle
              ListTile(
                title: const Text('Notification Listener Service'),
                subtitle: Text(provider.isListening ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: provider.isListening,
                  onChanged: (value) async {
                    if (value) {
                      // Check permission before enabling
                      final hasPermission =
                          await NotificationListenerService.isPermissionGranted();
                      if (!hasPermission) {
                        // Show dialog explaining permission requirement
                        if (context.mounted) {
                          await showDialog(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('Permission Required'),
                                  content: const Text(
                                    'Notification access permission is required to capture notifications. '
                                    'Please enable it in the settings above.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                          );
                        }
                        return;
                      }
                      await provider.startListening();
                    } else {
                      await provider.stopListening();
                    }
                  },
                ),
              ),
              const Divider(),

              // System Tray Removal Toggle
              SwitchListTile(
                title: const Text('Remove Notifications from Shade'),
                subtitle: const Text(
                  'Disable to keep notifications in the shade after they are captured.',
                ),
                value: _removeSystemTrayNotification,
                onChanged: (value) async {
                  setState(() {
                    _removeSystemTrayNotification = value;
                  });
                  await _saveSetting(value);
                  await NotificationService().updateRemoveSystemTraySetting(
                    value,
                  );
                },
              ),
              const Divider(),

              // Battery Optimization Tip
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: const Text('Tip: Lock Notification Hub in Recents'),
                subtitle: const Text(
                  'For best reliability, lock Notification Hub in your recent apps list.\n'
                  'On some devices (Xiaomi, Oppo, Vivo, etc.), swipe down on the app in recents and tap the lock icon.\n'
                  'This prevents the system from killing the app in the background.',
                ),
              ),

              // App Management
              ListTile(
                title: const Text('Manage Apps'),
                subtitle: const Text('Select which apps to track'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/apps'),
              ),

              const Divider(),

              ListTile(
                title: const Text('About'),
                subtitle: const Text(
                  'Notification Hub captures and organizes your notifications',
                ),
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
                    builder:
                        (context) => AlertDialog(
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
                    children:
                        excludedApps.map((packageName) {
                          final appName = _getAppNameFromPackage(packageName);

                          return Dismissible(
                            key: ValueKey(packageName),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) async {
                              await provider.includeApp(packageName);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$appName will be tracked again',
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              title: Text(appName),
                              subtitle: Text(packageName),
                              trailing: Consumer<NotificationProvider>(
                                builder: (context, provider, child) {
                                  final isExcluded = provider.notifications.any(
                                    (n) => n.packageName == packageName,
                                  );
                                  return Switch(
                                    value: !isExcluded,
                                    onChanged: (value) async {
                                      if (value) {
                                        await provider.includeApp(packageName);
                                      } else {
                                        await provider.excludeApp(packageName);
                                      }
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
              FutureBuilder<int>(
                future: _loadHistoryDays(),
                builder: (context, snapshot) {
                  int currentDays =
                      snapshot.data ?? 7; // Default to 7 if no data
                  return ListTile(
                    // Wrap in ListTile for consistent padding/style
                    title: const Text('Keep History For'),
                    trailing: DropdownButton<int>(
                      value: currentDays,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 Day')),
                        DropdownMenuItem(value: 3, child: Text('3 Days')),
                        DropdownMenuItem(value: 7, child: Text('7 Days')),
                        DropdownMenuItem(value: 14, child: Text('14 Days')),
                        DropdownMenuItem(value: 30, child: Text('30 Days')),
                        DropdownMenuItem(value: 0, child: Text('Forever')),
                      ],
                      onChanged: (int? newValue) async {
                        if (newValue != null) {
                          await _saveHistoryDays(newValue);
                          // Optionally notify provider to reload history with new setting
                          provider
                              .loadHistory(); // Assuming loadHistory handles the setting
                        }
                      },
                    ),
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
      builder:
          (context) => AlertDialog(
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

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
