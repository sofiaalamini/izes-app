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
              description: 'Uma lista direta para decidir o proximo passo.',
              compact: true,
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const _InlineState(message: 'Carregando alertas...', loading: true),
            if (snapshot.hasError)
              _InlineState(
                message: 'Nao foi possivel atualizar os alertas agora.',
                actionLabel: 'Tentar novamente',
                onAction: _reload,
              ),
            if (!snapshot.hasError && snapshot.connectionState != ConnectionState.waiting) ...[
              if ((snapshot.data ?? const <AlertItem>[]).isEmpty)
                const _InlineState(
                  message: 'Nenhum alerta importante no momento.',
                ),
              ...(snapshot.data ?? const <AlertItem>[]).map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: IzesColors.line),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: _colorForLevel(alert.level),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  StatusBadge(level: alert.level, label: _labelForLevel(alert.level)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alert.detail,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
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
        return 'Atencao';
      case AlertLevel.ok:
        return 'Estavel';
    }
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
