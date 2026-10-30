import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import 'cache_service.dart';
import 'session_store.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService({http.Client? client, SessionStore? store}) {
    if (client != null) {
      _instance._client = client;
    }
    if (store != null) {
      _instance._store = store;
    }
    return _instance;
  }

  AuthService._internal();

  http.Client _client = http.Client();
  SessionStore _store = SecureSessionStore();
  Future<void>? _refreshing;

  /// Renova o token quando faltar menos que isso para expirar.
  static const _refreshMargin = Duration(minutes: 10);
  String? _accessToken;
  AuthUser? _currentUser;

  bool get isAuthenticated => _accessToken?.isNotEmpty == true;

  AuthUser? get currentUser => _currentUser;

  String get resolvedClientId {
    final userClientId = _currentUser?.clienteId.trim() ?? '';
    return userClientId.isNotEmpty ? userClientId : BackendConfig.clientId;
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('${BackendConfig.baseUrl}/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractMessage(response, fallback: 'Não foi possível entrar.'),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = '${data['access_token'] ?? ''}'.trim();
    final userJson = data['user'] as Map<String, dynamic>?;
    if (token.isEmpty || userJson == null) {
      throw const AuthException('Resposta de login inválida.');
    }

    _accessToken = token;
    _currentUser = AuthUser.fromJson(userJson);
    await _persist();
    notifyListeners();
  }

  /// Restaura a sessão salva no aparelho (chamar antes de abrir o app).
  Future<void> restoreSession() async {
    try {
      final raw = await _store.read();
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final token = '${data['token'] ?? ''}';
      final userJson = data['user'];
      final expiry = tokenExpiry(token);
      final stillValid =
          expiry != null &&
          expiry.isAfter(
            DateTime.now().toUtc().add(const Duration(seconds: 30)),
          );

      if (!stillValid || userJson is! Map<String, dynamic>) {
        await _store.clear();
        return;
      }

      _accessToken = token;
      _currentUser = AuthUser.fromJson(userJson);
      notifyListeners();
    } catch (error) {
      debugPrint('AuthService: sessão salva ignorada: $error');
      try {
        await _store.clear();
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    final token = _accessToken;
    final user = _currentUser;
    if (token == null || user == null) return;
    try {
      await _store.write(jsonEncode({'token': token, 'user': user.toJson()}));
    } catch (error) {
      debugPrint('AuthService: não foi possível salvar a sessão: $error');
    }
  }

  /// Data de expiração (claim `exp`) de um JWT, ou `null` se não for legível.
  static DateTime? tokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> register({
    required String nome,
    required String email,
    required String password,
    required String convite,
  }) async {
    final response = await _client.post(
      Uri.parse('${BackendConfig.baseUrl}/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome.trim(),
        'email': email.trim(),
        'password': password,
        'convite': convite.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractMessage(
          response,
          fallback: 'Não foi possível concluir o cadastro.',
        ),
      );
    }

    await login(email: email, password: password);
  }

  void logout() {
    _accessToken = null;
    _currentUser = null;
    unawaited(_store.clear().catchError((_) {}));
    unawaited(CacheService().clearAll());
    notifyListeners();
  }

  Future<String> getAccessToken() async {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw const AuthException('Sua sessão expirou. Entre novamente.');
    }

    final expiry = tokenExpiry(token);
    if (expiry != null &&
        expiry.difference(DateTime.now().toUtc()) < _refreshMargin) {
      await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    }

    final atual = _accessToken;
    if (atual == null || atual.isEmpty) {
      throw const AuthException('Sua sessão expirou. Entre novamente.');
    }
    return atual;
  }

  /// Troca o token por um novo antes de expirar. Sem rede, segue com o atual.
  Future<void> _refresh() async {
    final atual = _accessToken;
    if (atual == null) return;
    try {
      final response = await _client.post(
        Uri.parse('${BackendConfig.baseUrl}/auth/refresh'),
        headers: {'Authorization': 'Bearer $atual'},
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        logout();
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final novo = '${data['access_token'] ?? ''}'.trim();
      final userJson = data['user'];
      if (novo.isEmpty) return;
      _accessToken = novo;
      if (userJson is Map<String, dynamic>) {
        _currentUser = AuthUser.fromJson(userJson);
      }
      await _persist();
    } catch (error) {
      debugPrint('AuthService: renovação adiada (sem conexão?): $error');
    }
  }

  String _extractMessage(http.Response response, {required String fallback}) {
    if (response.statusCode == 429) {
      return 'Muitas tentativas. Aguarde um minuto e tente de novo.';
    }
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'cliente_id': clienteId,
    'role': role,
  };
}
