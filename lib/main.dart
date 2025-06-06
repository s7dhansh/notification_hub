import 'package:flutter/material.dart'
    show
        BuildContext,
        ColorScheme,
        Colors,
        MaterialApp,
        Brightness,
        StatelessWidget,
        ThemeData,
        Widget,
        WidgetsFlutterBinding,
        debugPrint,
        runApp,
        Builder;
// runApp is a top-level function and doesn't need to be shown explicitly.
import 'package:provider/provider.dart'
    show ChangeNotifierProvider, MultiProvider, Provider;
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:notification_listener_service/notification_listener_service.dart'
    show NotificationListenerService;

import 'providers/notification_provider.dart' show NotificationProvider;
import 'providers/subscription_provider.dart' show SubscriptionProvider;
import 'screens/home_screen.dart' show HomeScreen;
import 'screens/settings_screen.dart' show SettingsScreen;
import 'screens/dashboard_screen.dart' show DashboardScreen;
import 'screens/app_management_screen.dart' show AppManagementScreen;
import 'screens/subscription_screen.dart' show SubscriptionScreen;
import 'providers/theme_provider.dart';
import 'flavors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notification listener service
  try {
    // Check if permission is granted
    final hasPermission =
        await NotificationListenerService.isPermissionGranted();
    if (!hasPermission) {
      // This will be handled in the NotificationService class
      // but we pre-check here to ensure early initialization
    }
  } catch (e) {
    debugPrint('Error initializing notification listener service: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: FlavorConfig.title,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/apps': (context) => const AppManagementScreen(),
              '/subscription': (context) => const SubscriptionScreen(),
            },
          );
        },
      ),
    );
  }
}
