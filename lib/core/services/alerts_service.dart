import 'auth_service.dart';
import '../models/izes_models.dart';
import 'api_client.dart';

class AlertsService {
  AlertsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AlertItem>> fetchAlerts() async {
    final clientId = AuthService().resolvedClientId;
    if (clientId.isEmpty) {
      return const <AlertItem>[];
    }

    final data = await _apiClient.getJson(
      '/api/dashboard/cliente/$clientId/sensores',
      useAppToken: true,
    );

    final items = data['sensores'];
    if (items is! List) {
      return const <AlertItem>[];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .where((sensor) {
          final reading = sensor['ultima_leitura'] as Map<String, dynamic>?;
          return reading?['alerta_ativo'] == true ||
              reading?['nivel_critico'] == true;
        })
        .map(AlertItem.fromDashboardSensor)
        .toList();
  }
}
