import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izesapp/core/services/auth_service.dart';

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

final _loginOk = {
  'access_token': 'jwt',
  'user': {
    'id': 'u1',
    'nome': 'Teste',
    'email': 't@t.com',
    'cliente_id': 'agrisoil',
    'role': 'viewer',
  },
};

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.exemplo.com');
    AuthService().logout();
  });

  test('cadastro envia o convite e não envia cliente_id', () async {
    Map<String, dynamic>? corpo;
    final auth = AuthService(
      client: MockClient((request) async {
        if (request.url.path == '/auth/register') {
          corpo = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(200, {});
        }
        return _json(200, _loginOk);
      }),
    );

    await auth.register(
      nome: 'Pessoa',
      email: 'p@t.com',
      password: 'senha',
      convite: ' codigo-do-convite ',
    );

    expect(corpo!['convite'], 'codigo-do-convite');
    expect(corpo!.containsKey('cliente_id'), isFalse);
    expect(auth.isAuthenticated, isTrue);
  });

  test('convite inválido mostra a mensagem do backend', () async {
    final auth = AuthService(
      client: MockClient(
        (_) async => _json(400, {'detail': 'Convite inválido ou expirado.'}),
      ),
    );

    await expectLater(
      auth.register(nome: 'P', email: 'p@t.com', password: 's', convite: 'x'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Convite inválido'),
        ),
      ),
    );
    expect(auth.isAuthenticated, isFalse);
  });

  test('limite de tentativas vira mensagem clara', () async {
    final auth = AuthService(
      client: MockClient(
        (_) async =>
            _json(429, {'error': 'Rate limit exceeded: 10 per 1 minute'}),
      ),
    );

    await expectLater(
      auth.login(email: 't@t.com', password: 'errada'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Muitas tentativas'),
        ),
      ),
    );
  });
}
