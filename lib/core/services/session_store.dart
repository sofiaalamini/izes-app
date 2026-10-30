import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onde a sessão do usuário fica guardada entre aberturas do app.
abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

/// Armazenamento criptografado do sistema (Keystore no Android, Keychain no iOS).
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'izes_session';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Usado em testes: não persiste nada fora da memória do processo.
class MemorySessionStore implements SessionStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> clear() async => value = null;
}
