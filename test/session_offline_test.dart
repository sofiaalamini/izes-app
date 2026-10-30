import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izesapp/core/services/api_client.dart';
import 'package:izesapp/core/services/auth_service.dart';
import 'package:izesapp/core/services/cache_service.dart';
import 'package:izesapp/core/services/location_service.dart';
import 'package:izesapp/core/services/session_store.dart';
import 'package:izesapp/core/services/weather_service.dart';
import 'package:izesapp/core/utils/error_message.dart';
import 'package:izesapp/shared/widgets/offline_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

String _jwt(Duration validade) {
  String parte(Map<String, Object?> dados) =>
      base64Url.encode(utf8.encode(jsonEncode(dados))).replaceAll('=', '');
  final exp = DateTime.now().add(validade).millisecondsSinceEpoch ~/ 1000;
  return '${parte({'alg': 'HS256'})}.${parte({'sub': 'u1', 'exp': exp})}.assinatura';
}

Map<String, Object?> _usuario() => {
  'id': 'u1',
  'nome': 'Teste',
  'email': 't@t.com',
  'cliente_id': 'agrisoil',
  'role': 'viewer',
};

class _LocalizacaoFalsa implements LocationService {
  _LocalizacaoFalsa(this.posicao);

  final DeviceLocation? posicao;

  @override
  Future<DeviceLocation?> currentPosition() async => posicao;
}

Future<AuthService> _logar(MemorySessionStore store, {String? token}) async {
  final auth = AuthService(
    store: store,
    client: MockClient(
      (_) async => _json(200, {
        'access_token': token ?? _jwt(const Duration(hours: 1)),
        'user': _usuario(),
      }),
    ),
  );
  await auth.login(email: 't@t.com', password: 'senha');
  return auth;
}

void main() {
  late MemorySessionStore store;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.exemplo.com');
    SharedPreferences.setMockInitialValues({});
    store = MemorySessionStore();
    AuthService(store: store).logout();
    store.value = null;
  });

  group('sessão salva', () {
    test('login grava a sessão e ela volta ao reabrir o app', () async {
      await _logar(store);
      expect(store.value, isNotNull);

      // Simula fechar e abrir o app: estado em memória zerado, sessão no disco.
      final salvo = store.value;
      final auth = AuthService(store: store)..logout();
      store.value = salvo;
      expect(auth.isAuthenticated, isFalse);

      await auth.restoreSession();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.clienteId, 'agrisoil');
    });

    test('sessão com token expirado é descartada', () async {
      store.value = jsonEncode({
        'token': _jwt(const Duration(minutes: -5)),
        'user': _usuario(),
      });
      final auth = AuthService(store: store);

      await auth.restoreSession();

      expect(auth.isAuthenticated, isFalse);
      expect(store.value, isNull);
    });

    test('sessão corrompida não derruba o app e é limpa', () async {
      store.value = 'isto não é json';
      final auth = AuthService(store: store);

      await auth.restoreSession();

      expect(auth.isAuthenticated, isFalse);
      expect(store.value, isNull);
    });

    test('logout apaga a sessão salva', () async {
      final auth = await _logar(store);
      expect(store.value, isNotNull);

      auth.logout();
      await Future<void>.delayed(Duration.zero);

      expect(store.value, isNull);
      expect(auth.isAuthenticated, isFalse);
    });

    test('lê a data de expiração do JWT', () {
      final exp = AuthService.tokenExpiry(_jwt(const Duration(hours: 2)));
      expect(exp, isNotNull);
      expect(exp!.isAfter(DateTime.now().toUtc()), isTrue);
      expect(AuthService.tokenExpiry('nao-e-jwt'), isNull);
    });
  });

  group('renovação do token', () {
    test('token perto de expirar é trocado antes da requisição', () async {
      final novo = _jwt(const Duration(hours: 1));
      String? autorizacao;
      final auth = await _logar(store, token: _jwt(const Duration(minutes: 3)));
      AuthService(
        client: MockClient((request) async {
          autorizacao = request.headers['Authorization'];
          return _json(200, {'access_token': novo, 'user': _usuario()});
        }),
      );

      final usado = await auth.getAccessToken();

      expect(usado, novo);
      expect(autorizacao, startsWith('Bearer '));
      expect(jsonDecode(store.value!)['token'], novo);
    });

    test('renovação recusada (401) encerra a sessão', () async {
      final auth = await _logar(store, token: _jwt(const Duration(minutes: 3)));
      AuthService(client: MockClient((_) async => _json(401, {'detail': 'x'})));

      await expectLater(auth.getAccessToken(), throwsA(isA<AuthException>()));
      expect(auth.isAuthenticated, isFalse);
    });

    test('sem internet mantém o token atual até ele expirar', () async {
      final antigo = _jwt(const Duration(minutes: 3));
      final auth = await _logar(store, token: antigo);
      AuthService(
        client: MockClient((_) async => throw http.ClientException('sem rede')),
      );

      expect(await auth.getAccessToken(), antigo);
      expect(auth.isAuthenticated, isTrue);
    });

    test('token com bastante validade não é renovado', () async {
      var chamadas = 0;
      final auth = await _logar(store);
      AuthService(
        client: MockClient((_) async {
          chamadas++;
          return _json(200, {});
        }),
      );

      await auth.getAccessToken();

      expect(chamadas, 0);
    });
  });

  group('cache offline', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService()..markOnline();
    });

    ApiClient clienteCom(AuthService auth, http.Client http) =>
        ApiClient(authService: auth, client: http, cache: cache);

    test('sem conexão devolve o último dado salvo e avisa', () async {
      final auth = await _logar(store);
      await clienteCom(
        auth,
        MockClient((_) async => _json(200, {'total': 3})),
      ).getJson('/api/x', authenticated: true, cacheKey: 'k1');
      expect(cache.offlineSince.value, isNull);

      final offline = clienteCom(
        auth,
        MockClient((_) async => throw http.ClientException('sem rede')),
      );
      final data = await offline.getJson(
        '/api/x',
        authenticated: true,
        cacheKey: 'k1',
      );

      expect(data['total'], 3);
      expect(cache.offlineSince.value, isNotNull);
    });

    test('voltar a ter conexão limpa o aviso', () async {
      final auth = await _logar(store);
      cache.markOffline(DateTime.now());

      await clienteCom(
        auth,
        MockClient((_) async => _json(200, {'ok': true})),
      ).getJson('/api/x', authenticated: true, cacheKey: 'k2');

      expect(cache.offlineSince.value, isNull);
    });

    test('sem dado salvo o erro de conexão continua sendo erro', () async {
      final auth = await _logar(store);
      final api = clienteCom(
        auth,
        MockClient((_) async => throw http.ClientException('sem rede')),
      );

      await expectLater(
        api.getJson('/api/x', authenticated: true, cacheKey: 'nunca-salvo'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('erro do servidor (400/401/403) nunca vira dado antigo', () async {
      final auth = await _logar(store);
      await clienteCom(
        auth,
        MockClient((_) async => _json(200, {'total': 1})),
      ).getJson('/api/x', authenticated: true, cacheKey: 'k3');

      for (final status in [400, 403, 404]) {
        final api = clienteCom(
          auth,
          MockClient((_) async => _json(status, {'detail': 'no'})),
        );
        await expectLater(
          api.getJson('/api/x', authenticated: true, cacheKey: 'k3'),
          throwsA(isA<ApiException>()),
          reason: 'status $status',
        );
      }
    });

    test('servidor fora do ar (502/503/504) usa o dado salvo', () async {
      final auth = await _logar(store);
      await clienteCom(
        auth,
        MockClient((_) async => _json(200, {'total': 7})),
      ).getJson('/api/x', authenticated: true, cacheKey: 'k4');

      final api = clienteCom(
        auth,
        MockClient((_) async => _json(503, {'detail': 'indisponível'})),
      );
      final data = await api.getJson(
        '/api/x',
        authenticated: true,
        cacheKey: 'k4',
      );

      expect(data['total'], 7);
    });

    test('sair da conta apaga os dados salvos', () async {
      final auth = await _logar(store);
      await cache.save('sensores_agrisoil', {'total': 9});
      expect(await cache.read('sensores_agrisoil'), isNotNull);

      auth.logout();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(await cache.read('sensores_agrisoil'), isNull);
    });
  });

  group('clima pela localização do aparelho', () {
    final respostaAtual = {
      'localizacao': {
        'latitude': -24.95,
        'longitude': -53.45,
        'cidade': 'Cascavel',
      },
      'clima_atual': {
        'temperatura': 21.5,
        'sensacao_termica': 20.0,
        'umidade': 70,
        'descricao': 'nublado',
        'vento': 5.0,
      },
      'previsao_resumo': {
        'resumo': 'chuva',
        'probabilidade_chuva': 80,
        'precipitacao_mm': 4.0,
      },
      'alerta_clima': {
        'risco_geada': false,
        'risco_seca': false,
        'mensagem': '',
      },
    };

    Future<WeatherService> servico(DeviceLocation? posicao) async {
      final auth = await _logar(store);
      final api = ApiClient(
        authService: auth,
        cache: CacheService(),
        client: MockClient((request) async {
          if (request.url.path.startsWith('/api/sensores/')) {
            return _json(200, {'localizacao': {}}); // sensor sem coordenadas
          }
          if (request.url.path == '/api/clima/atual') {
            expect(request.url.queryParameters['lat'], '-24.95');
            expect(request.headers['Authorization'], startsWith('Bearer '));
            return _json(200, respostaAtual);
          }
          return _json(404, {'detail': 'rota inesperada'});
        }),
      );
      return WeatherService(
        apiClient: api,
        locationService: _LocalizacaoFalsa(posicao),
      );
    }

    test('sensor sem coordenadas usa o GPS do aparelho', () async {
      final clima = await (await servico(
        const DeviceLocation(-24.95, -53.45),
      )).getWeatherBySensor('S1');

      expect(clima.city, 'Cascavel');
      expect(clima.temperatureC, 21.5);
      expect(clima.humidity, 70);
      expect(clima.chanceOfRain, 80);
      expect(clima.windKph, closeTo(18, 0.01));
    });

    test('sem GPS explica o que fazer', () async {
      final service = await servico(null);

      await expectLater(
        service.getWeatherBySensor('S1'),
        throwsA(
          isA<WeatherException>().having(
            (e) => e.message,
            'message',
            contains('GPS'),
          ),
        ),
      );
    });
  });

  group('mensagemDeErro', () {
    test('usa a mensagem amigável da API e cai no padrão para o resto', () {
      expect(
        mensagemDeErro(
          const ApiException('HTTP 502: {}', statusCode: 502),
          padrao: 'padrão',
        ),
        contains('indisponível'),
      );
      expect(
        mensagemDeErro(
          const ApiException('HTTP 418: x', statusCode: 418),
          padrao: 'padrão',
        ),
        'padrão',
      );
      expect(mensagemDeErro(StateError('x'), padrao: 'padrão'), 'padrão');
      expect(
        mensagemDeErro(const AuthException('Sua sessão expirou.'), padrao: 'p'),
        'Sua sessão expirou.',
      );
    });
  });

  group('faixa de offline', () {
    testWidgets('aparece só quando há dado salvo sendo exibido', (
      tester,
    ) async {
      final fonte = ValueNotifier<DateTime?>(null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OfflineBanner(source: fonte)),
        ),
      );
      expect(find.textContaining('Sem conexão'), findsNothing);

      fonte.value = DateTime(2026, 10, 30, 14, 5);
      await tester.pump();
      expect(find.textContaining('Sem conexão'), findsOneWidget);
      expect(find.textContaining('30/10 14:05'), findsOneWidget);

      fonte.value = null;
      await tester.pump();
      expect(find.textContaining('Sem conexão'), findsNothing);
    });
  });
}
