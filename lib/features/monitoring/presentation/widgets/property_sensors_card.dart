import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/models/sensor_model.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/status_badge.dart';

class PropertySensorsCard extends StatelessWidget {
  const PropertySensorsCard({
    super.key,
    required this.sensors,
    this.selectedSensorId,
    this.onSensorSelected,
  });

  final List<SensorModel> sensors;
  final String? selectedSensorId;
  final ValueChanged<String>? onSensorSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensores da propriedade', style: theme.titleLarge),
          const SizedBox(height: 4),
          Text('Leituras mais recentes.', style: theme.bodyMedium),
          const SizedBox(height: 12),
          if (sensors.isEmpty)
            Text('Nenhuma leitura recente encontrada.', style: theme.bodyMedium)
          else
            ...sensors.map(
              (sensor) => _SensorTile(
                sensor: sensor,
                isSelected: sensor.id == selectedSensorId,
                onTap: onSensorSelected == null
                    ? null
                    : () => onSensorSelected!(sensor.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({
    required this.sensor,
    required this.isSelected,
    this.onTap,
  });

  final SensorModel sensor;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? IzesColors.greenSoft : IzesColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? IzesColors.green : IzesColors.line,
              ),
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
                          Text(
                            sensor.label.isEmpty ? 'Sensor' : sensor.label,
                            style: theme.titleMedium?.copyWith(
                              color: IzesColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sensor.location?.isNotEmpty == true
                                ? sensor.location!
                                : sensor.note,
                            style: theme.bodyMedium?.copyWith(
                              color: IzesColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusBadge(
                      level: _badgeLevel(sensor.status),
                      label: _statusLabel(sensor.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FactPill(
                      label: 'Temperatura',
                      value: _factValue(sensor, 'Temperatura'),
                    ),
                    _FactPill(
                      label: 'Umidade',
                      value: _factValue(sensor, 'Umidade'),
                    ),
                    _FactPill(label: 'pH', value: _factValue(sensor, 'pH')),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  sensor.note,
                  style: theme.labelMedium?.copyWith(color: IzesColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  sensor.lastReading == null
                      ? 'Nenhuma leitura recente encontrada.'
                      : 'Leitura de ${DateTimeFormatter.shortDateTime(sensor.lastReading)}',
                  style: theme.labelMedium?.copyWith(color: IzesColors.muted),
                ),
              ],
            ),
          ),
        ),
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
        return 'Estavel';
      case SensorStatus.attention:
        return 'Atencao';
      case SensorStatus.offline:
        return 'Urgente';
    }
  }

  String _factValue(SensorModel sensor, String label) {
    for (final fact in sensor.facts) {
      if (fact.label == label) {
        return fact.value;
      }
    }
    return '--';
  }
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: IzesColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IzesColors.line),
      ),
      child: Text(
        '$label: $value',
        style: theme.labelMedium?.copyWith(color: IzesColors.ink),
      ),
    );
  }
}
