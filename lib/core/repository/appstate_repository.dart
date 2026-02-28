// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velo/core/constants/constants.dart';

class AppStateRepository {
  static const String PropertyKey = 'property';
  static const String RuntimeKey = 'runtime';

  Map<String, dynamic> _properties = {};
  SharedPreferences? _pref;

  AppStateRepository();

  get properties => _properties;

  Future<int> get runtime async {
    _pref = _pref ?? await SharedPreferences.getInstance();
    return _pref?.getInt(RuntimeKey) ?? 0;
  }

  set runtime(value) {
    _pref = (_pref ??
        SharedPreferences.getInstance().then((pref) {
          _pref?.setInt(RuntimeKey, value);
          return null;
        })) as SharedPreferences?;
    _pref?.setInt(RuntimeKey, value);
  }

  Future<void> updateProperty(String key, dynamic value) async {
    _pref = _pref ?? await SharedPreferences.getInstance();

    _properties[key] = value;
    String propertyStr = jsonEncode(_properties);
    await _pref?.setString(PropertyKey, propertyStr);
  }

  dynamic getProperty(String key) => _properties[key];

  Future<dynamic> fetchProperty({String? key}) async {
    try {
      _pref = _pref ?? await SharedPreferences.getInstance();

      var propertyStr = _pref?.getString(PropertyKey) ?? "{}";
      _properties = jsonDecode(propertyStr);

      _pref?.getString(USERKEY) ?? '';

      return key != null ? _properties[key] : null;
    } catch (error) {
      return _properties;
    }
  }
}
