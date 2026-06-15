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
            message: 'Nao foi possivel atualizar o resumo agora.',
            onRetry: _reload,
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const _DashboardStateCard(
            message: 'Sem atualizacao no momento.',
          );
        }

        final summary = data.summary;
        final actions = data.alerts.take(3).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(
              eyebrow: 'dashboard',
              title: 'Visao geral do campo',
              description:
                  'Prioridades, leituras recentes e o pulso atual da operacao.',
              compact: true,
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
                          'Acoes prioritarias',
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
                      'Nenhuma acao critica no momento.',
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
      _dashboardFuture = _dashboardService.fetchDashboard();
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
      return 'Comece pelos sensores criticos e valide a recomendacao de manejo antes da proxima rodada de leituras.';
    }
    if (summary.attentionCount > 0) {
      return 'O dia pede observacao, com foco nos sensores que podem sair do ideal nas proximas horas.';
    }
    return 'O campo segue estavel, com espaco para uma checagem rapida de rotina.';
  }

  String _problemText(AlertItem alert) {
    if (alert.level == AlertLevel.urgent) {
      return 'Verificar ${alert.sensorName ?? 'este sensor'} agora.';
    }
    if (alert.level == AlertLevel.attention) {
      return '${alert.sensorName ?? 'Este sensor'} pede acompanhamento.';
    }
    return '${alert.sensorName ?? 'Sensor'} sem sinal de criticidade.';
  }

  String _recommendationText(AlertItem alert) {
    if (alert.ph != null && alert.ph != '--') {
      return 'pH fora do ideal. Recomenda-se revisar a condicao do solo.';
    }
    if (alert.humidity != null && alert.humidity != '--') {
      return 'Monitorar umidade nas proximas horas e comparar com a ultima leitura.';
    }
    if (alert.temperature != null && alert.temperature != '--') {
      return 'Conferir a variacao de temperatura e repetir a leitura se necessario.';
    }
    return 'Revisar a ultima leitura e decidir o proximo passo.';
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
