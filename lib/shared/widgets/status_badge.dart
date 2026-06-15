import 'package:flutter/material.dart';

import '../../core/models/izes_models.dart';
import '../../core/theme/izes_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.level, this.label});

  final AlertLevel level;
  final String? label;

  _BadgePalette get _palette {
    final normalized = _normalizeLabel(label ?? _defaultText).toLowerCase();

    if (normalized.contains('observação')) {
      return const _BadgePalette(
        background: IzesColors.observationSoft,
        foreground: IzesColors.observation,
      );
    }
    if (normalized.contains('atenção')) {
      return const _BadgePalette(
        background: IzesColors.attentionSoft,
        foreground: IzesColors.attention,
      );
    }
    if (normalized.contains('estável') || normalized.contains('tudo certo')) {
      return const _BadgePalette(
        background: IzesColors.greenSoft,
        foreground: IzesColors.green,
      );
    }
    if (normalized.contains('urgente') || normalized.contains('ação')) {
      return const _BadgePalette(
        background: IzesColors.urgentSoft,
        foreground: IzesColors.urgent,
      );
    }

    switch (level) {
      case AlertLevel.urgent:
        return const _BadgePalette(
          background: IzesColors.urgentSoft,
          foreground: IzesColors.urgent,
        );
      case AlertLevel.attention:
        return const _BadgePalette(
          background: IzesColors.attentionSoft,
          foreground: IzesColors.attention,
        );
      case AlertLevel.ok:
        return const _BadgePalette(
          background: IzesColors.greenSoft,
          foreground: IzesColors.green,
        );
    }
  }

  String get _defaultText {
    switch (level) {
      case AlertLevel.urgent:
        return 'Ação urgente';
      case AlertLevel.attention:
        return 'Atenção';
      case AlertLevel.ok:
        return 'Tudo certo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.foreground.withValues(alpha: 0.10)),
      ),
      child: Text(
        _normalizeLabel(label ?? _defaultText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: palette.foreground,
          fontSize: 10.5,
        ),
      ),
    );
  }

  String _normalizeLabel(String value) {
    return value
        .replaceAll('Acao', 'Ação')
        .replaceAll('acao', 'ação')
        .replaceAll('Atencao', 'Atenção')
        .replaceAll('atencao', 'atenção')
        .replaceAll('Estavel', 'Estável')
        .replaceAll('estavel', 'estável')
        .replaceAll('Observacao', 'Observação')
        .replaceAll('observacao', 'observação');
  }
}

class _BadgePalette {
  const _BadgePalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
