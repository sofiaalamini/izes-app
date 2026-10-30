import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izesapp/core/services/api_client.dart';
import 'package:izesapp/core/services/auth_service.dart';

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _login(AuthService auth) async {
  final loginClient = MockClient(
    (_) async => _json(200, {
      'access_token': 'jwt-do-usuario',
      'user': {
        'id': 'u1',
        'nome': 'Teste',
        'email': 't@t.com',
        'cliente_id': 'agrisoil',
        'role': 'viewer',
      },
    }),
  );
  AuthService(client: loginClient);
  await auth.login(email: 't@t.com', password: 'senha');
}

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.exemplo.com');
    AuthService().logout();
  });

  group('ApiException.friendlyMessage', () {
    test('mapeia status comuns para mensagens em português', () {
      expect(
        const ApiException('x', statusCode: 401).friendlyMessage,
        'Sua sessão expirou. Entre novamente.',
      );
      expect(
        const ApiException('x', statusCode: 403).friendlyMessage,
        'Você não tem acesso a este recurso.',
      );
      expect(
        const ApiException('x', statusCode: 413).friendlyMessage,
        contains('muito grande'),
      );
      expect(
        const ApiException('x', statusCode: 429).friendlyMessage,
        contains('Muitas solicitações'),
      );
    });

    test('erro 5xx não mostra JSON cru nem detalhe técnico', () {
      const erro = ApiException(
        'HTTP 502: {"detail":"Falha interna"}',
        statusCode: 502,
        detail: 'Falha interna',
      );
      expect(
        erro.friendlyMessage,
        'O servidor está indisponível no momento. Tente novamente em instantes.',
      );
      expect(erro.friendlyMessage, isNot(contains('HTTP')));
    });

    test('erro 4xx usa o detail do backend quando existe', () {
      const erro = ApiException(
        'HTTP 400: {"detail":"O arquivo enviado deve ser uma imagem válida."}',
        statusCode: 400,
        detail: 'O arquivo enviado deve ser uma imagem válida.',
      );
      expect(
        erro.friendlyMessage,
        'O arquivo enviado deve ser uma imagem válida.',
      );
    });
  });

  group('ApiClient', () {
    test('envia o JWT do usuário e nunca o X-App-Token', () async {
      final auth = AuthService();
      await _login(auth);

      late http.BaseRequest enviada;
      final api = ApiClient(
        authService: auth,
        client: MockClient((request) async {
          enviada = request;
          return _json(200, {'ok': true});
        }),
      );

      final data = await api.getJson('/api/dashboard/x', authenticated: true);

      expect(data['ok'], true);
      expect(enviada.headers['Authorization'], 'Bearer jwt-do-usuario');
      expect(enviada.headers.containsKey('X-App-Token'), isFalse);
    });

    test(
      'sem sessão não faz login automático e pede para entrar de novo',
      () async {
        var chamadas = 0;
        final api = ApiClient(
          authService: AuthService(),
          client: MockClient((_) async {
            chamadas++;
            return _json(200, {});
          }),
        );

        await expectLater(
          api.getJson('/api/dashboard/x', authenticated: true),
          throwsA(isA<AuthException>()),
        );
        expect(chamadas, 0);
      },
    );

    test('resposta 401 encerra a sessão e leva de volta ao login', () async {
      final auth = AuthService();
      await _login(auth);
      expect(auth.isAuthenticated, isTrue);

      final api = ApiClient(
        authService: auth,
        client: MockClient(
          (_) async => _json(401, {'detail': 'Token inválido'}),
        ),
      );

      await expectLater(
        api.getJson('/api/dashboard/x', authenticated: true),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(auth.isAuthenticated, isFalse);
    });

    test('guarda status e detail do erro do backend', () async {
      final auth = AuthService();
      await _login(auth);
      final api = ApiClient(
        authService: auth,
        client: MockClient(
          (_) async => _json(502, {
            'detail':
                'Não foi possível analisar a imagem com a OpenAI no momento.',
          }),
        ),
      );

      try {
        await api.postJson('/api/ia/chat', authenticated: true);
        fail('deveria lançar ApiException');
      } on ApiException catch (erro) {
        expect(erro.statusCode, 502);
        expect(erro.detail, contains('OpenAI'));
        expect(erro.friendlyMessage, isNot(contains('{')));
      }
    });

    test(
      'requisição que não responde estoura o timeout com mensagem clara',
      () async {
        final api = ApiClient(
          authService: AuthService(),
          timeout: const Duration(milliseconds: 50),
          client: MockClient((_) => Completer<http.Response>().future),
        );

        await expectLater(
          api.getJson('/api/clima/atual'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('demorou demais'),
            ),
          ),
        );
      },
    );
  });
}
