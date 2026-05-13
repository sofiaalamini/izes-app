import '../config/backend_config.dart';
import '../models/izes_models.dart';
import 'alerts_service.dart';
import 'api_client.dart';

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.alerts,
    required this.updatedAtLabel,
  });

  final DashboardSummary summary;
  final List<AlertItem> alerts;
  final String updatedAtLabel;
}

class DashboardService {
  DashboardService({ApiClient? apiClient, AlertsService? alertsService})
    : _apiClient = apiClient ?? ApiClient(),
      _alertsService = alertsService ?? AlertsService();

  final ApiClient _apiClient;
  final AlertsService _alertsService;

  Future<DashboardData> fetchDashboard() async {
    if (!BackendConfig.hasClientId) {
      throw const ApiDashboardException(
        'API_CLIENT_ID nao configurado no .env.',
      );
    }

    final sensorsData = await _apiClient.getJson(
      '/api/dashboard/cliente/${BackendConfig.clientId}/sensores',
      useAppToken: true,
    );
    List<AlertItem> alerts;
    try {
      alerts = await _alertsService.fetchAlerts();
    } catch (_) {
      alerts = const <AlertItem>[];
    }

    final sensors = (sensorsData['sensores'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final urgentCount = alerts.where((alert) => alert.level == AlertLevel.urgent).length;
    final attentionCount = alerts
        .where((alert) => alert.level == AlertLevel.attention)
        .length;
    final okCount = sensors.length - urgentCount - attentionCount;

    return DashboardData(
      summary: DashboardSummary(
        urgentCount: urgentCount,
        attentionCount: attentionCount,
        okCount: okCount < 0 ? 0 : okCount,
        sensorCount: sensors.length,
      ),
      alerts: alerts.take(3).toList(),
      updatedAtLabel: '${sensorsData['atualizado_em'] ?? 'sem sincronizacao'}',
    );
  }
}

class ApiDashboardException implements Exception {
  const ApiDashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
