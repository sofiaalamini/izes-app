import 'package:flutter/material.dart';

import '../../../../core/theme/izes_theme.dart';

/// Resposta da IA organizada em blocos: título de seção, parágrafos e passos numerados.
class AiReplyView extends StatelessWidget {
  const AiReplyView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final blocks = parseAiReply(text);
    final theme = Theme.of(context).textTheme;
    final body = theme.bodyLarge?.copyWith(color: IzesColors.ink, height: 1.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0)
            SizedBox(
              height: blocks[i].isHeading
                  ? 14
                  : blocks[i].muted
                  ? 12
                  : 6,
            ),
          _buildBlock(blocks[i], body, theme),
        ],
      ],
    );
  }

  Widget _buildBlock(AiReplyBlock block, TextStyle? body, TextTheme theme) {
    if (block.isHeading) {
      final level = _levelColors(block.text);
      return Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: level?.$1 ?? IzesColors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              block.text,
              style: theme.titleSmall?.copyWith(
                color: IzesColors.greenDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    if (block.step != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1, right: 10),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: IzesColors.greenSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${block.step}',
              style: const TextStyle(
                color: IzesColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: Text.rich(_inline(block.text, body), style: body)),
        ],
      );
    }

    if (block.muted) {
      return Text(
        block.text,
        style: theme.bodySmall?.copyWith(color: IzesColors.muted, height: 1.4),
      );
    }

    final level = _levelColors(block.text);
    if (level != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: level.$2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          block.text,
          style: body?.copyWith(color: level.$1, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Text.rich(_inline(block.text, body), style: body);
  }

  /// Cor do nível de atenção (Baixo, Atenção, Urgente), quando o texto é só isso.
  (Color, Color)? _levelColors(String value) {
    switch (value.trim().toLowerCase().replaceAll(RegExp(r'[.:]$'), '')) {
      case 'baixo':
        return (IzesColors.green, IzesColors.greenSoft);
      case 'atenção':
      case 'atencao':
        return (IzesColors.observation, IzesColors.observationSoft);
      case 'urgente':
        return (IzesColors.urgent, IzesColors.urgentSoft);
    }
    return null;
  }

  /// Converte **negrito** em texto em negrito.
  TextSpan _inline(String value, TextStyle? base) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;
    for (final match in pattern.allMatches(value)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
      cursor = match.end;
    }
    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor)));
    }
    return TextSpan(children: spans);
  }
}

class AiReplyBlock {
  const AiReplyBlock(
    this.text, {
    this.isHeading = false,
    this.step,
    this.muted = false,
  });

  final String text;
  final bool isHeading;
  final int? step;

  /// Aviso ou convite no fim da resposta: aparece pequeno e apagado.
  final bool muted;
}

/// Títulos curtos e diretos para quem lê no campo.
const _headingLabels = {
  'situação': 'Como está',
  'situacao': 'Como está',
  'risco': 'O risco',
  'o que fazer agora': 'O que fazer',
};

final _headingPattern = RegExp(r'^(?:#{1,4}\s*)?\**([^:\n]{2,40}):\**$');
final _stepPattern = RegExp(r'^(\d{1,2})[.)]\s+(.*)$');
final _bulletPattern = RegExp(r'^[-•*]\s+(.*)$');
final _inlineSectionPattern = RegExp(
  r'^(Situação|Situacao|Risco|Atenção|Atencao):\s+(.+)$',
  caseSensitive: false,
);
final _closingOfferPattern = RegExp(r'é só pedir', caseSensitive: false);

String _headingLabel(String raw) =>
    _headingLabels[raw.trim().toLowerCase()] ?? raw.trim();

bool _isAttention(String label) {
  final value = label.trim().toLowerCase();
  return value == 'atenção' || value == 'atencao';
}

/// Quebra a resposta em linhas classificadas. Texto sem estrutura vira parágrafos simples.
List<AiReplyBlock> parseAiReply(String text) {
  final blocks = <AiReplyBlock>[];
  var inAttention = false;
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      final label = heading.group(1)!;
      inAttention = _isAttention(label);
      // A seção "Atenção" não ganha título: o texto dela vira só uma nota pequena.
      if (!inAttention) {
        blocks.add(AiReplyBlock(_headingLabel(label), isHeading: true));
      }
      continue;
    }
    final inline = _inlineSectionPattern.firstMatch(line);
    if (inline != null) {
      final label = inline.group(1)!;
      if (_isAttention(label)) {
        blocks.add(AiReplyBlock(inline.group(2)!, muted: true));
      } else {
        blocks.add(AiReplyBlock(_headingLabel(label), isHeading: true));
        blocks.add(AiReplyBlock(inline.group(2)!));
      }
      inAttention = false;
      continue;
    }
    final step = _stepPattern.firstMatch(line);
    if (step != null) {
      inAttention = false;
      blocks.add(AiReplyBlock(step.group(2)!, step: int.parse(step.group(1)!)));
      continue;
    }
    final bullet = _bulletPattern.firstMatch(line);
    blocks.add(
      AiReplyBlock(
        bullet != null ? '• ${bullet.group(1)}' : line,
        muted: inAttention || _closingOfferPattern.hasMatch(line),
      ),
    );
  }
  return blocks;
}
