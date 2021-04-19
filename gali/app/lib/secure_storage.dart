import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = FlutterSecureStorage();

  /// Writes the given key to the secure storage.
  static Future writeSecureData(String key, String value) async {
    var writeData = await _storage.write(key: key, value: value);
    return writeData;
  }

  /// returns the requested key from secure storage.
  static Future readSecureData(String key) async {
    var readData = await _storage.read(key: key);
    return readData;
  }

  /// Deletes the key stored in secure storage.
  static Future deleteSecureData(String key) async {
    var deleteData = await _storage.delete(key: key);
    return deleteData;
  }
}
