import 'backend_type.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const BackendType backend = BackendType.api;

  static const String _Url = "http://api.esera.works";

  static String get apiBaseUrl {
    if (kIsWeb) {
      return "http://api.esera.works";
    }
    return _Url;
  }
}
