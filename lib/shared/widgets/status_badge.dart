import 'package:flutter/material.dart';

import '../../core/models/izes_models.dart';
import '../../core/theme/izes_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.level, this.label});

  final AlertLevel level;
  final String? label;

  Color get _background {
    switch (level) {
      case AlertLevel.urgent:
        return IzesColors.urgentSoft;
      case AlertLevel.attention:
        return IzesColors.attentionSoft;
      case AlertLevel.ok:
        return IzesColors.greenSoft;
    }
  }

  Color get _foreground {
    switch (level) {
      case AlertLevel.urgent:
        return IzesColors.urgent;
      case AlertLevel.attention:
        return IzesColors.attention;
      case AlertLevel.ok:
        return IzesColors.green;
    }
  }

  String get _text {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _foreground.withValues(alpha: 0.10)),
      ),
      child: Text(
        label ?? _text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: _foreground, fontSize: 10.5),
      ),
    );
  }
}
