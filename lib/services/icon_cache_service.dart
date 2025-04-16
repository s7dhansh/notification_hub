import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IconCacheService {
  static final IconCacheService _instance = IconCacheService._internal();
  factory IconCacheService() => _instance;
  IconCacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};
  static const String _iconCacheKey = 'app_icons_cache';

  Future<void> cacheIcon(String packageName, String base64Icon) async {
    try {
      final iconBytes = base64Decode(base64Icon);
      _memoryCache[packageName] = iconBytes;

      final prefs = await SharedPreferences.getInstance();
      final iconCache = prefs.getStringList(_iconCacheKey) ?? [];
      final existingIndex = iconCache.indexWhere(
        (item) => item.startsWith('$packageName:'),
      );

      if (existingIndex >= 0) {
        iconCache[existingIndex] = '$packageName:$base64Icon';
      } else {
        iconCache.add('$packageName:$base64Icon');
      }

      await prefs.setStringList(_iconCacheKey, iconCache);
    } catch (e) {
      debugPrint('Failed to cache icon for $packageName: $e');
    }
  }

  Future<Uint8List?> getIcon(String packageName) async {
    // Check memory cache first
    if (_memoryCache.containsKey(packageName)) {
      return _memoryCache[packageName];
    }

    // Try loading from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final iconCache = prefs.getStringList(_iconCacheKey) ?? [];
      final iconEntry = iconCache.firstWhere(
        (item) => item.startsWith('$packageName:'),
        orElse: () => '',
      );

      if (iconEntry.isNotEmpty) {
        final base64Icon = iconEntry.split(':')[1];
        final iconBytes = base64Decode(base64Icon);
        _memoryCache[packageName] = iconBytes;
        return iconBytes;
      }
    } catch (e) {
      debugPrint('Failed to load icon for $packageName: $e');
    }

    return null;
  }

  Future<void> clearCache() async {
    _memoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_iconCacheKey);
  }
}
