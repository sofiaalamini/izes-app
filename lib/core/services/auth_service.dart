import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService({http.Client? client}) {
    if (client != null) {
      _instance._client = client;
    }
    return _instance;
  }

  AuthService._internal();

  http.Client _client = http.Client();
  String? _accessToken;
  AuthUser? _currentUser;

  bool get isAuthenticated => _accessToken?.isNotEmpty == true;

  AuthUser? get currentUser => _currentUser;

  String get resolvedClientId => _currentUser?.clienteId ?? BackendConfig.clientId;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${BackendConfig.baseUrl}/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_extractMessage(response, fallback: 'Nao foi possivel entrar.'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = '${data['access_token'] ?? ''}'.trim();
    final userJson = data['user'] as Map<String, dynamic>?;
    if (token.isEmpty || userJson == null) {
      throw const AuthException('Resposta de login invalida.');
    }

    _accessToken = token;
    _currentUser = AuthUser.fromJson(userJson);
    notifyListeners();
  }

  Future<void> register({
    required String nome,
    required String email,
    required String password,
    required String clienteId,
  }) async {
    final response = await _client.post(
      Uri.parse('${BackendConfig.baseUrl}/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome.trim(),
        'email': email.trim(),
        'password': password,
        'cliente_id': clienteId.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractMessage(response, fallback: 'Nao foi possivel concluir o cadastro.'),
      );
    }

    await login(email: email, password: password);
  }

  void logout() {
    _accessToken = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<String> getAccessToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken!;
    }

    if (!BackendConfig.hasAuthCredentials) {
      throw const AuthException(
        'API_AUTH_EMAIL e API_AUTH_PASSWORD nao configurados no .env.',
      );
    }

    final response = await _client.post(
      Uri.parse('${BackendConfig.baseUrl}/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': BackendConfig.authEmail,
        'password': BackendConfig.authPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractMessage(
          response,
          fallback: 'Nao foi possivel iniciar sua sessao.',
        ),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = '${data['access_token'] ?? ''}'.trim();
    if (token.isEmpty) {
      throw const AuthException('Backend nao retornou access_token.');
    }

    _accessToken = token;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson != null) {
      _currentUser = AuthUser.fromJson(userJson);
    }
    return token;
  }

  String _extractMessage(http.Response response, {required String fallback}) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = '${decoded['detail'] ?? ''}'.trim();
        if (detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}

    return fallback;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.clienteId,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: '${json['id'] ?? ''}',
      nome: '${json['nome'] ?? ''}',
      email: '${json['email'] ?? ''}',
      clienteId: '${json['cliente_id'] ?? ''}',
      role: '${json['role'] ?? 'viewer'}',
    );
  }

  final String id;
  final String nome;
  final String email;
  final String clienteId;
  final String role;
}
