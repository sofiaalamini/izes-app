import 'package:flutter_test/flutter_test.dart';
import 'package:izesapp/core/utils/convite.dart';

const _codigo =
    'eyJhbGciOiJIUzI1NiJ9.eyJ0eXAiOiJjb252aXRlIn0.assinatura-123_ABC';

void main() {
  group('normalizarConvite', () {
    test('mantém o código como veio', () {
      expect(normalizarConvite(_codigo), _codigo);
    });

    test('tira espaços, quebras de linha e tabs', () {
      expect(normalizarConvite('  $_codigo \n'), _codigo);
      expect(
        normalizarConvite(
          '${_codigo.substring(0, 20)}\n${_codigo.substring(20)}',
        ),
        _codigo,
      );
      expect(
        normalizarConvite(
          '${_codigo.substring(0, 20)} \t ${_codigo.substring(20)}',
        ),
        _codigo,
      );
    });

    test('tira aspas retas, curvas e colchetes', () {
      expect(normalizarConvite('"$_codigo"'), _codigo);
      expect(normalizarConvite("'$_codigo'"), _codigo);
      expect(normalizarConvite('\u201c$_codigo\u201d'), _codigo);
      expect(normalizarConvite('<$_codigo>'), _codigo);
      expect(normalizarConvite('[$_codigo]'), _codigo);
    });

    test('aceita a linha inteira do JSON copiada do Swagger', () {
      expect(normalizarConvite('"convite": "$_codigo",'), _codigo);
      expect(normalizarConvite('"convite":"$_codigo"'), _codigo);
    });

    test('não mexe nos caracteres válidos do código', () {
      expect(normalizarConvite('a-b_c.d-e_f.g-h_i'), 'a-b_c.d-e_f.g-h_i');
    });

    test('texto vazio continua vazio', () {
      expect(normalizarConvite(''), '');
      expect(normalizarConvite('  "" \n'), '');
    });
  });

  group('conviteDoLink', () {
    test('lê o convite da URL', () {
      final link = Uri.parse(
        'https://abc.trycloudflare.com/app/?convite=${Uri.encodeQueryComponent(_codigo)}',
      );
      expect(conviteDoLink(link), _codigo);
    });

    test('sem convite ou vazio devolve null', () {
      expect(conviteDoLink(Uri.parse('https://abc.com/app/')), isNull);
      expect(conviteDoLink(Uri.parse('https://abc.com/app/?convite=')), isNull);
      expect(
        conviteDoLink(Uri.parse('https://abc.com/app/?convite=%20%22%22')),
        isNull,
      );
    });

    test('ignora outros parâmetros', () {
      final link = Uri.parse('https://abc.com/app/?x=1&convite=$_codigo&y=2');
      expect(conviteDoLink(link), _codigo);
    });

    test('limpa sobras no valor do link', () {
      final link = Uri.parse(
        'https://abc.com/app/?convite=${Uri.encodeQueryComponent('"$_codigo"')}',
      );
      expect(conviteDoLink(link), _codigo);
    });
  });
}
