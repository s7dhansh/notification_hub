enum Flavor { development, production }

class FlavorValues {
  FlavorValues({
    required this.baseUrl,
    required this.appName,
    required this.packageName,
    required this.debugMode,
  });

  final String baseUrl;
  final String appName;
  final String packageName;
  final bool debugMode;
}

class FlavorConfig {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.development:
        return 'Notification Hub Dev';
      case Flavor.production:
        return 'Notification Hub';
      default:
        return 'title';
    }
  }

  static FlavorValues get values {
    switch (appFlavor) {
      case Flavor.development:
        return FlavorValues(
          baseUrl: 'https://dev-api.notificationhub.com',
          appName: 'Notification Hub Dev',
          packageName: 'in.appkari.notihub.dev',
          debugMode: true,
        );
      case Flavor.production:
        return FlavorValues(
          baseUrl: 'https://api.notificationhub.com',
          appName: 'Notification Hub',
          packageName: 'in.appkari.notihub',
          debugMode: false,
        );
      default:
        return FlavorValues(
          baseUrl: '',
          appName: '',
          packageName: '',
          debugMode: false,
        );
    }
  }
}
