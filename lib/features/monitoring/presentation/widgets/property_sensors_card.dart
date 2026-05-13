import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/models/sensor_model.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/status_badge.dart';

class PropertySensorsCard extends StatelessWidget {
  const PropertySensorsCard({super.key, required this.sensors});

  final List<SensorModel> sensors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensores da propriedade', style: theme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Leituras carregadas do dashboard real do backend.',
            style: theme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...sensors.map(
            (sensor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: IzesColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: IzesColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sensor.label, style: theme.titleMedium),
                              const SizedBox(height: 4),
                              Text(sensor.primaryValue, style: theme.headlineMedium),
                              if (sensor.location != null) ...[
                                const SizedBox(height: 4),
                                Text(sensor.location!, style: theme.bodyMedium),
                              ],
                            ],
                          ),
                        ),
                        StatusBadge(
                          level: _badgeLevel(sensor.status),
                          label: _statusLabel(sensor.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(sensor.note, style: theme.bodyMedium),
                    if (sensor.facts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sensor.facts
                            .map(
                              (fact) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: IzesColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: IzesColors.line),
                                ),
                                child: Text(
                                  '${fact.label}: ${fact.value}',
                                  style: theme.labelMedium,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      sensor.lastReading == null
                          ? 'Ultima leitura: indisponivel'
                          : 'Ultima leitura: ${DateFormat("dd/MM HH:mm").format(sensor.lastReading!)}',
                      style: theme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AlertLevel _badgeLevel(SensorStatus status) {
    switch (status) {
      case SensorStatus.online:
        return AlertLevel.ok;
      case SensorStatus.attention:
        return AlertLevel.attention;
      case SensorStatus.offline:
        return AlertLevel.urgent;
    }
  }

  String _statusLabel(SensorStatus status) {
    switch (status) {
      case SensorStatus.online:
        return 'Online';
      case SensorStatus.attention:
        return 'Atencao';
      case SensorStatus.offline:
        return 'Offline';
    }
  }
}
