import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/models/sensor_model.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../core/utils/date_time_formatter.dart';
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

    if (sensors.isEmpty) {
      return Text(
        'Nenhum sensor encontrado para esta propriedade.',
        style: theme.bodyMedium,
      );
    }

    return Column(
      children: sensors
          .map(
            (sensor) => _SensorTile(
              sensor: sensor,
              isSelected: sensor.id == selectedSensorId,
              onTap: onSensorSelected == null
                  ? null
                  : () => onSensorSelected!(sensor.id),
            ),
          )
          .toList(),
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
    final statusLabel = _statusLabel(sensor.status);
    final summary = _summaryText(sensor);
    final recommendation = _recommendationText(sensor);
    final lastReading = sensor.lastReading == null
        ? 'Nenhuma leitura recente encontrada.'
        : 'Ultima leitura: ${DateTimeFormatter.shortDateTime(sensor.lastReading)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: IzesColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? IzesColors.green : IzesColors.line,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 230),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sensor.label.isEmpty ? 'Sensor' : sensor.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleMedium?.copyWith(
                                color: IzesColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sensor.location?.isNotEmpty == true
                                  ? sensor.location!
                                  : sensor.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall?.copyWith(
                                color: IzesColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        level: _badgeLevel(sensor.status),
                        label: statusLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    summary,
                    style: theme.titleMedium?.copyWith(color: IzesColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recommendation,
                    style: theme.bodyMedium?.copyWith(color: IzesColors.muted),
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
                        label: 'Umidade do solo',
                        value: _factValue(sensor, 'Umidade'),
                      ),
                      _FactPill(label: 'pH', value: _factValue(sensor, 'pH')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        lastReading,
                        style: theme.labelMedium?.copyWith(
                          color: IzesColors.muted,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: IzesColors.greenSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Base do clima acima',
                            style: theme.labelMedium?.copyWith(
                              color: IzesColors.greenDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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

  String _summaryText(SensorModel sensor) {
    switch (sensor.status) {
      case SensorStatus.online:
        return 'Leitura recente recebida e sensor estavel.';
      case SensorStatus.attention:
        return 'Este sensor exige acompanhamento agora.';
      case SensorStatus.offline:
        return 'Sem leitura recente para apoiar a decisao.';
    }
  }

  String _recommendationText(SensorModel sensor) {
    switch (sensor.status) {
      case SensorStatus.online:
        return 'Continue monitorando as proximas atualizacoes ao longo do dia.';
      case SensorStatus.attention:
        return 'Revise as leituras mais recentes e confirme se o manejo precisa de ajuste.';
      case SensorStatus.offline:
        return 'Verifique conexao, energia ou envio de leitura deste sensor.';
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: IzesColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: IzesColors.line),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.labelMedium?.copyWith(color: IzesColors.ink),
      ),
    );
  }
}
