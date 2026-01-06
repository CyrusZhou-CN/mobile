import '../services/storage_service.dart';

import '../app/locator.dart';

class Config {
  static var configContainer = locator<StorageService>().getHiveBox('config');

  bool get isLoggedIn {
    try {
      return configContainer.get('isLoggedIn', defaultValue: false);
    } catch (e) {
      print('Error getting isLoggedIn from config: $e');
      return false;
    }
  }

  String? get userId {
    try {
      return Uri.decodeFull(configContainer.get('userId', defaultValue: ""));
    } catch (e) {
      print('Error getting userId from config: $e');
      return "";
    }
  }

  String get user {
    try {
      return configContainer.get('user');
    } catch (e) {
      print('Error getting user from config: $e');
      return "";
    }
  }

  String? get primaryCacheKey {
    if (baseUrl == null || userId == null) return null;
    return "$baseUrl$userId";
  }

  String get version {
    try {
      return configContainer.get('version');
    } catch (e) {
      print('Error getting version from config: $e');
      return "";
    }
  }

  String? get baseUrl {
    try {
      return configContainer.get('baseUrl');
    } catch (e) {
      print('Error getting baseUrl from config: $e');
      return null;
    }
  }

  Uri? get uri {
    if (baseUrl == null) return null;
    return Uri.parse(baseUrl!);
  }

  static Future set(String k, dynamic v) async {
    configContainer.put(k, v);
  }

  static Future clear() async {
    configContainer.clear();
  }

  static Future remove(String k) async {
    configContainer.delete(k);
  }
}
