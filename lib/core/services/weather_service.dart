import '../config/backend_config.dart';
import '../models/weather_model.dart';
import 'api_client.dart';

class WeatherService {
  WeatherService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<WeatherModel> fetchCurrentWeather() async {
    if (!BackendConfig.hasClientId) {
      throw const WeatherException(
        'API_CLIENT_ID nao configurado no .env.',
      );
    }
    final clientId = BackendConfig.clientId;

    final sensorsData = await _apiClient.getJson('/api/sensores/$clientId');
    final sensors = (sensorsData['sensores'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (sensors.isEmpty) {
      throw const WeatherException(
        'Nenhum sensor cadastrado no backend para consultar clima.',
      );
    }

    final firstSensorId = '${sensors.first['sensor_id'] ?? ''}';
    final detail = await _apiClient.getJson('/api/sensores/$clientId/$firstSensorId');
    final location = detail['localizacao'] as Map<String, dynamic>? ?? const {};
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    if (latitude == null || longitude == null) {
      throw const WeatherException(
        'Sensor cadastrado sem latitude/longitude para consultar clima.',
      );
    }

    final data = await _apiClient.getJson(
      '/api/clima/sensor/$firstSensorId/clima-atual',
      queryParameters: {
        'cliente_id': clientId,
        'latitude': '$latitude',
        'longitude': '$longitude',
      },
    );
    final current = data['clima_atual'] as Map<String, dynamic>? ?? const {};

    final temperatureC = _asDouble(current['temperatura_celsius']);
    final feelsLikeC = _asDouble(current['sensacao_termica']);
    final humidity = _asInt(current['umidade_relativa']);
    final precipitationMm = _asDouble(current['precipitacao']);
    final chanceOfRain = _extractChanceOfRain(data);
    final windKph = _asDouble(current['velocidade_vento']);
    final city = '${location['municipio'] ?? 'Municipio'}';
    final region = '${location['estado'] ?? ''}';

    return WeatherModel(
      city: city,
      region: region,
      temperatureC: temperatureC,
      feelsLikeC: feelsLikeC == 0 ? temperatureC : feelsLikeC,
      humidity: humidity,
      precipitationMm: precipitationMm,
      chanceOfRain: chanceOfRain,
      condition: '${current['descricao'] ?? current['condicao'] ?? 'Sem dados'}',
      windKph: windKph,
      agriculturalRecommendation: _buildRecommendation(
        backendAlert: '${data['alerta_clima'] ?? ''}'.trim(),
        dryRisk: _asDouble(data['indice_risco_seca']),
        temperatureC: temperatureC,
        humidity: humidity,
        precipitationMm: precipitationMm,
        chanceOfRain: chanceOfRain,
        windKph: windKph,
      ),
      fetchedAt: DateTime.now(),
    );
  }

  int _extractChanceOfRain(Map<String, dynamic> data) {
    final forecast = data['previsao_proximas_horas'];
    if (forecast is List && forecast.isNotEmpty) {
      final first = forecast.first;
      if (first is Map<String, dynamic>) {
        return _asInt(first['precipitacao_probabilidade']);
      }
    }
    return 0;
  }

  String _buildRecommendation({
    required String backendAlert,
    required double dryRisk,
    required double temperatureC,
    required int humidity,
    required double precipitationMm,
    required int chanceOfRain,
    required double windKph,
  }) {
    if (backendAlert.isNotEmpty) {
      return backendAlert;
    }
    if (dryRisk >= 60) {
      return 'Backend aponta risco elevado de seca para este sensor.';
    }
    if (chanceOfRain >= 60 || precipitationMm >= 3) {
      return 'Evite pulverizacao hoje.';
    }
    if (temperatureC >= 32) {
      return 'Priorize irrigacao no inicio da manha ou fim da tarde.';
    }
    if (humidity <= 35) {
      return 'Atencao ao estresse hidrico da cultura.';
    }
    if (windKph >= 22) {
      return 'Revise operacoes sensiveis ao vento antes de aplicar insumos.';
    }
    return 'Condicoes estaveis para manejo, com monitoramento ao longo do dia.';
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}

class WeatherException implements Exception {
  const WeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}
