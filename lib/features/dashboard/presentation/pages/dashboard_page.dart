import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/services/dashboard_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();

  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dashboardFuture = _dashboardService.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _DashboardStateCard(
            message: 'Não foi possível atualizar o resumo agora.',
            onRetry: _reload,
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const _DashboardStateCard(
            message: 'Sem atualização no momento.',
          );
        }

        final summary = data.summary;
        final actions = data.alerts.take(3).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(
              eyebrow: 'dashboard',
              title: 'Visão geral do campo',
              description:
                  'Prioridades, leituras recentes e o pulso atual da operação.',
              compact: true,
            ),
            const SizedBox(height: 16),
            AppSurfaceCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(18),
              backgroundColor: IzesColors.surface,
              borderColor: IzesColors.line,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: IzesColors.greenSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Painel de hoje',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: IzesColors.greenDark),
                        ),
                      ),
                      Text(
                        data.updatedAtLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _heroHeadline(summary),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _heroSupport(summary),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniPill(
                        label: '${summary.urgentCount} urgentes',
                        foreground: IzesColors.urgent,
                        background: IzesColors.urgentSoft,
                      ),
                      _MiniPill(
                        label: '${summary.attentionCount} em observação',
                        foreground: IzesColors.observation,
                        background: IzesColors.observationSoft,
                      ),
                      _MiniPill(
                        label: '${summary.okCount} estáveis',
                        foreground: IzesColors.green,
                        background: IzesColors.greenSoft,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OverviewInfoCard(
              title: 'Resumo do dia',
              body: _summaryLine(summary),
              highlight: data.updatedAtLabel,
            ),
            const SizedBox(height: 16),
            AppSurfaceCard(
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ações prioritárias',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${actions.length} itens',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (actions.isEmpty)
                    Text(
                      'Nenhuma ação crítica no momento.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ...actions.map(_buildAlertRow),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _reload() {
    setState(() {
      _loadData();
    });
  }

  Widget _buildAlertRow(AlertItem alert) {
    final problem = _problemText(alert);
    final recommendation = _recommendationText(alert);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IzesColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentForLevel(alert.level).withValues(alpha: 0.18),
        ),
      ),
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
                  color: _accentForLevel(alert.level).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForLevel(alert.level),
                  size: 16,
                  color: _accentForLevel(alert.level),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.sensorName ?? alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: IzesColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.location ?? alert.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(level: alert.level, label: alert.label),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            problem,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: IzesColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DataChip(label: 'Temp.', value: alert.temperature ?? '--'),
              _DataChip(label: 'Umidade', value: alert.humidity ?? '--'),
              _DataChip(label: 'pH', value: alert.ph ?? '--'),
            ],
          ),
        ],
      ),
    );
  }

  String _summaryLine(DashboardSummary summary) {
    if (summary.urgentCount > 0) {
      return 'Comece pelos sensores críticos e valide a recomendação de manejo antes da próxima rodada de leituras.';
    }
    if (summary.attentionCount > 0) {
      return 'O dia pede observação, com foco nos sensores que podem sair do ideal nas próximas horas.';
    }
    return 'O campo segue estável, com espaço para uma checagem rápida de rotina.';
  }

  String _heroHeadline(DashboardSummary summary) {
    if (summary.urgentCount > 0) {
      return '${_countText(summary.urgentCount, 'sensor precisa', 'sensores precisam')} de atenção imediata.';
    }
    if (summary.attentionCount > 0) {
      return '${_countText(summary.attentionCount, 'sensor pede', 'sensores pedem')} acompanhamento nas próximas horas.';
    }
    return 'Operação estável neste momento.';
  }

  String _heroSupport(DashboardSummary summary) {
    if (summary.urgentCount > 0) {
      return 'Priorize os alertas críticos e confira a leitura mais recente dos sensores afetados.';
    }
    if (summary.attentionCount > 0) {
      return 'Acompanhe os sensores em observação e revise uma nova leitura ao longo do dia.';
    }
    return 'Os sensores ativos seguem sem sinal forte de criticidade.';
  }

  String _countText(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
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
          return 'Verificar ${alert.sensorName ?? 'este sensor'} agora.';
        }
        if (alert.level == AlertLevel.attention) {
          return '${alert.sensorName ?? 'Este sensor'} pede acompanhamento.';
        }
        return '${alert.sensorName ?? 'Sensor'} sem sinal de criticidade.';
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
        return 'Revisar a última leitura e decidir o próximo passo.';
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

  Color _accentForLevel(AlertLevel level) {
    switch (level) {
      case AlertLevel.urgent:
        return IzesColors.urgent;
      case AlertLevel.attention:
        return IzesColors.attention;
      case AlertLevel.ok:
        return IzesColors.green;
    }
  }

  IconData _iconForLevel(AlertLevel level) {
    switch (level) {
      case AlertLevel.urgent:
        return Icons.priority_high_rounded;
      case AlertLevel.attention:
        return Icons.schedule_rounded;
      case AlertLevel.ok:
        return Icons.eco_outlined;
    }
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

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _DashboardStateCard extends StatelessWidget {
  const _DashboardStateCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: IzesColors.surface,
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

class _OverviewInfoCard extends StatelessWidget {
  const _OverviewInfoCard({
    required this.title,
    required this.body,
    this.highlight,
  });

  final String title;
  final String body;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      borderRadius: 16,
      backgroundColor: IzesColors.surfaceSoft,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (highlight != null) ...[
            Text(
              highlight!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: IzesColors.ink),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
