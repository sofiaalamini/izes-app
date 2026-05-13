import 'package:flutter/material.dart';

import '../../../../core/config/backend_config.dart';
import '../../../../core/models/izes_models.dart';
import '../../../../core/services/dashboard_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/metric_card.dart';
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
            message: '${snapshot.error}',
            onRetry: _reload,
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const _DashboardStateCard(message: 'Sem dados do backend.');
        }

        final summary = data.summary;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader(
              eyebrow: 'Dashboard',
              title:
                  'Cliente ${BackendConfig.clientId} com leitura do backend ativa.',
              description:
                  'O IZES usa sensores e alertas retornados pela API para priorizar o dia.',
            ),
            const SizedBox(height: 16),
            AppSurfaceCard(
              backgroundColor: IzesColors.greenSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ultima sincronizacao',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.updatedAtLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dados vindos do endpoint /api/dashboard/cliente/{id}/sensores.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 560 ? 2 : 1,
              childAspectRatio: 1.7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                MetricCard(
                  label: 'Acao urgente',
                  value: '${summary.urgentCount}',
                  note: 'Alertas criticos ou altos retornados pelo backend.',
                  tint: IzesColors.urgentSoft,
                ),
                MetricCard(
                  label: 'Atencao',
                  value: '${summary.attentionCount}',
                  note: 'Alertas medios que pedem acompanhamento.',
                  tint: IzesColors.attentionSoft,
                ),
                MetricCard(
                  label: 'Tudo certo',
                  value: '${summary.okCount}',
                  note: 'Sensores sem alerta ativo na ultima leitura.',
                  tint: IzesColors.greenSoft,
                ),
                MetricCard(
                  label: 'Sensores',
                  value: '${summary.sensorCount}',
                  note: 'Total recebido no dashboard do backend.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alertas de hoje',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (data.alerts.isEmpty)
                    Text(
                      'Nenhum alerta retornado pelo backend.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ...data.alerts.map(_buildAlertRow),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_outlined, color: IzesColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
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
