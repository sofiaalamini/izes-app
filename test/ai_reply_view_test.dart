import 'package:flutter_test/flutter_test.dart';
import 'package:izesapp/features/ai_assistant/presentation/widgets/ai_reply_view.dart';

void main() {
  test('separa títulos, parágrafos e passos numerados', () {
    final blocks = parseAiReply(
      'Situação:\nSolo seco.\n\nO que fazer agora:\n1. Irrigue hoje.\n2. Meça de novo.',
    );

    expect(blocks.map((b) => b.text), [
      'Como está',
      'Solo seco.',
      'O que fazer',
      'Irrigue hoje.',
      'Meça de novo.',
    ]);
    expect(blocks[0].isHeading, isTrue);
    expect(blocks[1].isHeading, isFalse);
    expect(blocks[3].step, 1);
    expect(blocks[4].step, 2);
  });

  test('Atenção e convite final viram notas apagadas, sem título', () {
    final blocks = parseAiReply(
      'Situação: Solo seco.\n\nRisco: Planta murcha.\n\n'
      'O que fazer agora:\n1. Irrigue.\n\n'
      'Atenção: Não aplique dose exata.\n\nTambém posso comparar. É só pedir.',
    );

    expect(blocks.map((b) => b.text), [
      'Como está',
      'Solo seco.',
      'O risco',
      'Planta murcha.',
      'O que fazer',
      'Irrigue.',
      'Não aplique dose exata.',
      'Também posso comparar. É só pedir.',
    ]);
    expect(blocks[1].muted, isFalse);
    expect(blocks[6].muted, isTrue);
    expect(blocks[7].muted, isTrue);
  });

  test('texto sem estrutura vira parágrafos simples', () {
    final blocks = parseAiReply('Tudo certo com o solo.');
    expect(blocks.single.isHeading, isFalse);
    expect(blocks.single.step, isNull);
  });
}
