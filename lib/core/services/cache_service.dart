import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Último JSON bom de uma requisição, com a hora em que foi salvo.
class CachedJson {
  const CachedJson(this.data, this.savedAt);

  final Map<String, dynamic> data;
  final DateTime savedAt;
}

/// Guarda as últimas respostas bem-sucedidas para mostrar sem internet.
///
/// As chaves incluem o cliente (ex.: `sensores_agrisoil`) e tudo é apagado no
/// logout, para um usuário nunca ver dados salvos de outra conta.
class CacheService {
  factory CacheService() => _instance;

  CacheService._();

  static final CacheService _instance = CacheService._();
  static const _prefix = 'izes_cache_';

  /// Não nulo enquanto a tela mostra dados salvos por falta de conexão.
  final ValueNotifier<DateTime?> offlineSince = ValueNotifier<DateTime?>(null);

  Future<void> save(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'data': data,
        }),
      );
    } catch (error) {
      debugPrint('Cache: não foi possível salvar "$key": $error');
    }
  }

  Future<CachedJson?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse('${decoded['savedAt']}')?.toLocal();
      final data = decoded['data'];
      if (savedAt == null || data is! Map<String, dynamic>) return null;
      return CachedJson(data, savedAt);
    } catch (_) {
      return null;
    }
  }

  void markOffline(DateTime savedAt) => offlineSince.value = savedAt;

  void markOnline() => offlineSince.value = null;

  Future<void> clearAll() async {
    offlineSince.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
