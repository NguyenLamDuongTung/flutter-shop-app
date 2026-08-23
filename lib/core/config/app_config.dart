import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
  }
}
