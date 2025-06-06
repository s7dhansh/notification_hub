import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import 'flavors.dart';
import 'main.dart' show MyApp;

Future<void> main() async {
  FlavorConfig.appFlavor = Flavor.production;

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
