import '../models/izes_models.dart';
import '../utils/date_time_formatter.dart';
import 'alerts_service.dart';
import 'api_client.dart';
import 'auth_service.dart';

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
    final clientId = AuthService().resolvedClientId;
    if (clientId.isEmpty) {
      throw const ApiDashboardException(
        'Cliente nao configurado para carregar o dashboard.',
      );
    }

    final sensorsData = await _apiClient.getJson(
      '/api/dashboard/cliente/$clientId/sensores',
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
      updatedAtLabel: DateTimeFormatter.shortDateTime(sensorsData['atualizado_em']),
    );
  }
}

class ApiDashboardException implements Exception {
  const ApiDashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
