import 'package:flutter_test/flutter_test.dart';
import 'package:izesapp/core/config/backend_config.dart';

String _resolve(
  String? raw, {
  bool isWeb = false,
  String page = 'http://localhost:5000/',
  bool isAndroid = false,
}) => BackendConfig.resolveBaseUrl(
  raw,
  isWeb: isWeb,
  pageUri: Uri.parse(page),
  isAndroid: isAndroid,
);

void main() {
  group('app web servido pelo backend em /app', () {
    test('usa a origem da página, ignorando API_BASE_URL', () {
      expect(
        _resolve(
          'http://127.0.0.1:8000',
          isWeb: true,
          page: 'https://abc.trycloudflare.com/app/',
        ),
        'https://abc.trycloudflare.com',
      );
    });

    test('vale também sem a barra final e com rota interna', () {
      expect(
        _resolve(null, isWeb: true, page: 'https://abc.exemplo.com/app'),
        'https://abc.exemplo.com',
      );
      expect(
        _resolve(null, isWeb: true, page: 'https://abc.exemplo.com:8443/app/x'),
        'https://abc.exemplo.com:8443',
      );
    });

    test('um caminho parecido (/aplicativo) não conta', () {
      expect(
        _resolve(
          'http://192.168.0.5:8000',
          isWeb: true,
          page: 'https://abc.exemplo.com/aplicativo/',
        ),
        'http://192.168.0.5:8000',
      );
    });

    test('fora da web o caminho /app é ignorado', () {
      expect(
        _resolve(
          'http://192.168.0.5:8000',
          page: 'https://abc.exemplo.com/app/',
        ),
        'http://192.168.0.5:8000',
      );
    });
  });

  group('demais plataformas (comportamento anterior)', () {
    test('usa API_BASE_URL e tira a barra final', () {
      expect(_resolve('http://192.168.0.5:8000/'), 'http://192.168.0.5:8000');
    });

    test('Android com localhost aponta para 10.0.2.2', () {
      expect(
        _resolve('http://127.0.0.1:8000', isAndroid: true),
        'http://10.0.2.2:8000',
      );
      expect(
        _resolve('http://localhost:9000', isAndroid: true),
        'http://10.0.2.2:9000',
      );
    });

    test('web em Chrome do Android não troca localhost por 10.0.2.2', () {
      expect(
        _resolve('http://localhost:8000', isWeb: true, isAndroid: true),
        'http://localhost:8000',
      );
    });

    test('sem API_BASE_URL cai no backend local', () {
      expect(_resolve(null), 'http://127.0.0.1:8000');
      expect(_resolve(''), 'http://127.0.0.1:8000');
      expect(_resolve(null, isAndroid: true), 'http://10.0.2.2:8000');
      expect(
        _resolve(null, isWeb: true, isAndroid: true),
        'http://127.0.0.1:8000',
      );
    });
  });
}
