import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  static const _androidEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const _localBaseUrl = 'http://127.0.0.1:8000';

  /// No APK em celular físico, API_BASE_URL deve ser o IP do notebook na
  /// mesma rede Wi-Fi (ex.: http://192.168.0.10:8000).
  static String get baseUrl {
    final raw = dotenv.env['API_BASE_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      debugPrint('API_BASE_URL ausente no .env. Usando backend local.');
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return _androidEmulatorBaseUrl;
      }
      return _localBaseUrl;
    }

    final normalized = raw.endsWith('/')
        ? raw.substring(0, raw.length - 1)
        : raw;
    final isLocalhost =
        normalized.startsWith('http://localhost:') ||
        normalized.startsWith('http://127.0.0.1:');

    // O emulador Android acessa o host de desenvolvimento por 10.0.2.2.
    if (isLocalhost && defaultTargetPlatform == TargetPlatform.android) {
      final port = Uri.parse(normalized).port;
      return 'http://10.0.2.2:$port';
    }

    return normalized;
  }

  static String get clientId => dotenv.env['API_CLIENT_ID']?.trim() ?? '';

  static bool get hasClientId => clientId.isNotEmpty;
}
