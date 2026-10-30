import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:izesapp/core/services/auth_service.dart';

void main() {
  test('restaura normalmente quando o armazenamento responde', () async {
    var restaurou = false;

    await restoreSessionSafely(() async => restaurou = true);

    expect(restaurou, isTrue);
  });

  test(
    'armazenamento que nunca responde não trava a abertura do app',
    () async {
      final travado = Completer<void>();

      final inicio = DateTime.now();
      await restoreSessionSafely(
        () => travado.future,
        timeout: const Duration(milliseconds: 50),
      );

      expect(DateTime.now().difference(inicio).inMilliseconds, lessThan(2000));
      expect(travado.isCompleted, isFalse);
    },
  );

  test('erro ao ler a sessão não derruba o app', () async {
    await expectLater(
      restoreSessionSafely(() async => throw StateError('storage quebrado')),
      completes,
    );
  });

  test('erro assíncrono tardio também é engolido', () async {
    await expectLater(
      restoreSessionSafely(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw Exception('falhou depois');
      }),
      completes,
    );
  });
}
