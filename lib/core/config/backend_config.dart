import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  static const _androidEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const _railwayBaseUrl =
      'https://teste-railway-izes-agro-production.up.railway.app';

  static String get baseUrl {
    final raw = dotenv.env['API_BASE_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      if (kIsWeb) {
        return _railwayBaseUrl;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _androidEmulatorBaseUrl;
        default:
          return _railwayBaseUrl;
      }
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String get clientId => dotenv.env['API_CLIENT_ID']?.trim() ?? '';

  static String get appToken => dotenv.env['API_APP_TOKEN']?.trim() ?? '';

  static String get authEmail => dotenv.env['API_AUTH_EMAIL']?.trim() ?? '';

  static String get authPassword =>
      dotenv.env['API_AUTH_PASSWORD']?.trim() ?? '';

  static bool get hasClientId => clientId.isNotEmpty;

  static bool get hasAppToken => appToken.isNotEmpty;

  static bool get hasAuthCredentials =>
      authEmail.isNotEmpty && authPassword.isNotEmpty;
}
