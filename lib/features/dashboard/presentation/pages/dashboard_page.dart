import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/services/dashboard_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/metric_card.dart';
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
          return const _DashboardStateCard(message: 'Sem atualizacao no momento.');
        }

        final summary = data.summary;
        final actions = data.alerts.take(3).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSurfaceCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              backgroundColor: IzesColors.greenSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hoje', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text(
                    'A propriedade segue com ${summary.sensorCount} sensores em acompanhamento.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ultima leitura: ${data.updatedAtLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MiniPill(
                        icon: Icons.priority_high_rounded,
                        label: '${summary.urgentCount} urgente',
                        foreground: IzesColors.urgent,
                        background: IzesColors.urgentSoft,
                      ),
                      const SizedBox(width: 8),
                      _MiniPill(
                        icon: Icons.schedule_rounded,
                        label: '${summary.attentionCount} em observacao',
                        foreground: IzesColors.attention,
                        background: IzesColors.attentionSoft,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: MediaQuery.sizeOf(context).width < 390 ? 1.18 : 1.32,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                MetricCard(
                  label: 'Urgente',
                  value: '${summary.urgentCount}',
                  note: 'Agir agora',
                  tint: IzesColors.urgentSoft,
                ),
                MetricCard(
                  label: 'Atencao',
                  value: '${summary.attentionCount}',
                  note: 'Observar',
                  tint: IzesColors.attentionSoft,
                ),
                MetricCard(
                  label: 'Estavel',
                  value: '${summary.okCount}',
                  note: 'Sem alerta',
                  tint: IzesColors.greenSoft,
                ),
                MetricCard(
                  label: 'Sensores',
                  value: '${summary.sensorCount}',
                  note: 'Ativos',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppSurfaceCard(
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo do dia',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _summaryLine(summary),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppSurfaceCard(
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${summary.sensorCount} pontos ativos',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppSurfaceCard(
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acoes prioritarias',
                    style: Theme.of(context).textTheme.titleMedium,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: _accentForLevel(alert.level),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  alert.detail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(level: alert.level, label: alert.label),
        ],
      ),
    );
  }

  String _summaryLine(DashboardSummary summary) {
    if (summary.urgentCount > 0) {
      return 'Comece pelos pontos urgentes e revise os alertas ainda pela manha.';
    }
    if (summary.attentionCount > 0) {
      return 'O dia pede acompanhamento, mas sem sinais de criticidade alta.';
    }
    return 'O campo segue estavel neste momento.';
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
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
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
