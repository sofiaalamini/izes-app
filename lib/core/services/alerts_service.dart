import '../models/izes_models.dart';
import 'api_client.dart';

class AlertsService {
  AlertsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AlertItem>> fetchAlerts() async {
    final data = await _apiClient.getJson(
      '/api/alertas',
      authenticated: true,
      queryParameters: const {'limite_dias': '7'},
    );

    final items = data['alertas'];
    if (items is! List) {
      return const <AlertItem>[];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(AlertItem.fromApiAlertas)
        .toList();
  }
}
