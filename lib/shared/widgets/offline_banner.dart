import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/cache_service.dart';
import '../../core/theme/izes_theme.dart';

/// Faixa que avisa quando a tela está mostrando dados salvos, sem conexão.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, ValueListenable<DateTime?>? source})
    : _source = source;

  final ValueListenable<DateTime?>? _source;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: _source ?? CacheService().offlineSince,
      builder: (context, savedAt, _) {
        if (savedAt == null) return const SizedBox.shrink();
        final hora = DateFormat('dd/MM HH:mm').format(savedAt);
        return Container(
          width: double.infinity,
          color: IzesColors.urgentSoft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: IzesColors.urgent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sem conexão. Mostrando dados salvos de $hora.',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: IzesColors.urgent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
