import 'package:flutter/material.dart' show BuildContext, Colors, ColorScheme, MaterialApp, StatelessWidget, ThemeData, Widget, WidgetsFlutterBinding, runApp;
import 'package:provider/provider.dart' show ChangeNotifierProvider;

import 'providers/notification_provider.dart' show NotificationProvider;
import 'screens/home_screen.dart' show HomeScreen;
import 'screens/settings_screen.dart' show SettingsScreen;
import 'screens/dashmon_screen.dart' show DashmonScreen;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationProvider(),
      child: MaterialApp(
        title: 'Notification Hub',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/dashmon': (context) => const DashmonScreen(),
        },
      ),
    );
  }
}
