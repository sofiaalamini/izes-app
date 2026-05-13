import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/services/alerts_service.dart';
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
              eyebrow: 'Alertas inteligentes',
              title: 'So o que pede acao urgente, atencao ou pode seguir estavel.',
              description:
                  'Leitura simples com dados do endpoint /api/alertas do backend.',
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator()),
            if (snapshot.hasError)
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Recarregar'),
                    ),
                  ],
                ),
              ),
            if (!snapshot.hasError && snapshot.connectionState != ConnectionState.waiting) ...[
              if ((snapshot.data ?? const <AlertItem>[]).isEmpty)
                const AppSurfaceCard(
                  child: Text('Nenhum alerta retornado pelo backend.'),
                ),
              ...(snapshot.data ?? const <AlertItem>[]).map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBadge(level: alert.level, label: alert.label),
                        const SizedBox(height: 12),
                        Text(
                          alert.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.detail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
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
}
