import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/services/alerts_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final AlertsService _alertsService = AlertsService();

  late Future<List<AlertItem>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _alertsService.fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AlertItem>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(
              eyebrow: 'Alertas',
              title: 'Prioridades do dia',
              description:
                  'Veja rapidamente o que exige ação, revisão ou monitoramento.',
              compact: true,
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const _InlineState(
                message: 'Carregando alertas...',
                loading: true,
              ),
            if (snapshot.hasError)
              _InlineState(
                message: 'Não foi possível atualizar os alertas agora.',
                actionLabel: 'Tentar novamente',
                onAction: _reload,
              ),
            if (!snapshot.hasError &&
                snapshot.connectionState != ConnectionState.waiting) ...[
              if ((snapshot.data ?? const <AlertItem>[]).isEmpty)
                const _InlineState(
                  message: 'Nenhum alerta importante no momento.',
                ),
              ...(snapshot.data ?? const <AlertItem>[]).map(
                (alert) => _AlertCard(
                  alert: alert,
                  color: _colorForLevel(alert.level),
                  label: _labelForLevel(alert.level),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _reload() {
    setState(() {
      _alertsFuture = _alertsService.fetchAlerts();
    });
  }

  Color _colorForLevel(AlertLevel level) {
    switch (level) {
      case AlertLevel.urgent:
        return IzesColors.urgent;
      case AlertLevel.attention:
        return IzesColors.attention;
      case AlertLevel.ok:
        return IzesColors.green;
    }
  }

  String _labelForLevel(AlertLevel level) {
    switch (level) {
      case AlertLevel.urgent:
        return 'Urgente';
      case AlertLevel.attention:
        return 'Atenção';
      case AlertLevel.ok:
        return 'Estável';
    }
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.color,
    required this.label,
  });

  final AlertItem alert;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final problem = _problemText(alert);
    final recommendation = _recommendationText(alert);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurfaceCard(
        borderRadius: 16,
        backgroundColor: IzesColors.surface,
        borderColor: color.withValues(alpha: 0.18),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconForLevel(alert.level),
                    size: 16,
                    color: color,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.sensorName ?? alert.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.location ?? alert.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusBadge(level: alert.level, label: label),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              problem,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.titleMedium?.copyWith(color: IzesColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              recommendation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ValuePill(
                  label: 'Temperatura',
                  value: alert.temperature ?? '--',
                ),
                _ValuePill(label: 'Umidade', value: alert.humidity ?? '--'),
                _ValuePill(label: 'pH', value: alert.ph ?? '--'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForLevel(AlertLevel level) {
    switch (level) {
      case AlertLevel.urgent:
        return Icons.crisis_alert_rounded;
      case AlertLevel.attention:
        return Icons.schedule_rounded;
      case AlertLevel.ok:
        return Icons.eco_outlined;
    }
  }

  String _problemText(AlertItem alert) {
    switch (_issueForAlert(alert)) {
      case _AlertIssue.noReading:
        return 'Sem leitura recente para ${alert.sensorName ?? 'este sensor'}.';
      case _AlertIssue.phLow:
        return 'pH abaixo do ideal em ${alert.sensorName ?? 'este sensor'}.';
      case _AlertIssue.phHigh:
        return 'pH acima do ideal em ${alert.sensorName ?? 'este sensor'}.';
      case _AlertIssue.humidityLow:
        return 'Umidade do solo baixa em ${alert.sensorName ?? 'este sensor'}.';
      case _AlertIssue.humidityHigh:
        return 'Umidade do solo elevada em ${alert.sensorName ?? 'este sensor'}.';
      case _AlertIssue.temperatureHigh:
        return 'Temperatura elevada em ${alert.sensorName ?? 'este sensor'}.';
      case _AlertIssue.temperatureLow:
        return 'Temperatura baixa em ${alert.sensorName ?? 'este sensor'}.';
      case _AlertIssue.generic:
        if (alert.level == AlertLevel.urgent) {
          return 'Ação imediata recomendada para ${alert.sensorName ?? 'este sensor'}.';
        }
        if (alert.level == AlertLevel.attention) {
          return '${alert.sensorName ?? 'Este sensor'} exige acompanhamento.';
        }
        return '${alert.sensorName ?? 'Sensor'} segue estável.';
    }
  }

  String _recommendationText(AlertItem alert) {
    switch (_issueForAlert(alert)) {
      case _AlertIssue.noReading:
        return 'Verifique conexão, energia ou envio de leitura antes da próxima análise.';
      case _AlertIssue.phLow:
        return 'Revisar a acidez do solo e avaliar correção para elevar o pH.';
      case _AlertIssue.phHigh:
        return 'Revisar a alcalinidade do solo e validar a disponibilidade de nutrientes.';
      case _AlertIssue.humidityLow:
        return 'Programar irrigação e comparar a próxima leitura para confirmar a recuperação.';
      case _AlertIssue.humidityHigh:
        return 'Suspender irrigação e verificar drenagem para evitar encharcamento.';
      case _AlertIssue.temperatureHigh:
        return 'Acompanhar aquecimento do solo e revisar necessidade de irrigação ou proteção.';
      case _AlertIssue.temperatureLow:
        return 'Monitorar a temperatura do solo e evitar manejo sensível até a estabilização.';
      case _AlertIssue.generic:
        return 'Revisar o contexto da leitura e definir a próxima ação no campo.';
    }
  }

  _AlertIssue _issueForAlert(AlertItem alert) {
    final ph = _parseValue(alert.ph);
    final humidity = _parseValue(alert.humidity);
    final temperature = _parseValue(alert.temperature);

    if (ph == null && humidity == null && temperature == null) {
      return _AlertIssue.noReading;
    }
    if (ph != null && ph < 5.5) {
      return _AlertIssue.phLow;
    }
    if (ph != null && ph > 7.5) {
      return _AlertIssue.phHigh;
    }
    if (humidity != null && humidity < 35) {
      return _AlertIssue.humidityLow;
    }
    if (humidity != null && humidity > 85) {
      return _AlertIssue.humidityHigh;
    }
    if (temperature != null && temperature > 35) {
      return _AlertIssue.temperatureHigh;
    }
    if (temperature != null && temperature < 10) {
      return _AlertIssue.temperatureLow;
    }
    return _AlertIssue.generic;
  }

  double? _parseValue(String? raw) {
    if (raw == null) return null;
    final normalized = raw
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9\.\-]'), '')
        .trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}

enum _AlertIssue {
  noReading,
  phLow,
  phHigh,
  humidityLow,
  humidityHigh,
  temperatureHigh,
  temperatureLow,
  generic,
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: IzesColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IzesColors.line),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: IzesColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading) ...[
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(height: 12),
          ],
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
