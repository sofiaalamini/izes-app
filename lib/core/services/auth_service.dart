import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/backend_config.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;

  Future<String> getAccessToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken!;
    }

    if (!BackendConfig.hasAuthCredentials) {
      throw const AuthException(
        'API_AUTH_EMAIL e API_AUTH_PASSWORD nao configurados no .env.',
      );
    }

    final uri = Uri.parse('${BackendConfig.baseUrl}/auth/login');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': BackendConfig.authEmail,
        'password': BackendConfig.authPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        'Falha no login do backend (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = '${data['access_token'] ?? ''}'.trim();
    if (token.isEmpty) {
      throw const AuthException('Backend nao retornou access_token.');
    }

    _accessToken = token;
    return token;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
