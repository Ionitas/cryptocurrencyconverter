import 'package:shared_preferences/shared_preferences.dart';

/// Interface for storage service
abstract class IStorageService {
  Future<String?> getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool?> getBool(String key);
  Future<bool> setBool(String key, bool value);
  bool containsKey(String key);
}

/// Implementation of storage service using SharedPreferences
/// Use getIt<StorageService>() to access the singleton instance
class StorageService implements IStorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    final p = await prefs;
    return p.setString(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final p = await prefs;
    return p.getBool(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    final p = await prefs;
    return p.setBool(key, value);
  }

  @override
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}
