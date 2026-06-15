import 'package:flutter/foundation.dart';

import '../models/weather_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class WeatherService {
  WeatherService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<WeatherModel> getWeatherBySensor(String sensorId) async {
    final clientId = AuthService().resolvedClientId;
    if (clientId.isEmpty) {
      throw const WeatherException(
        'Cliente não configurado para consultar o clima do sensor.',
      );
    }

    if (sensorId.trim().isEmpty) {
      throw const WeatherException('Sensor inválido para consultar o clima.');
    }

    try {
      final detail = await _apiClient.getJson(
        '/api/sensores/$clientId/$sensorId',
        authenticated: true,
      );
      final location =
          detail['localizacao'] as Map<String, dynamic>? ?? const {};
      final latitude = _asDouble(location['latitude']);
      final longitude = _asDouble(location['longitude']);

      if (latitude == null || longitude == null) {
        throw const WeatherException(
          'Sensor sem latitude/longitude para consultar o clima.',
        );
      }

      final data = await _apiClient.getJson(
        '/api/clima/sensor/$sensorId/clima-atual',
        queryParameters: {
          'cliente_id': clientId,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );

      final current = data['clima_atual'] as Map<String, dynamic>? ?? const {};
      final localizacao =
          data['localizacao'] as Map<String, dynamic>? ?? location;
      final forecast = _firstForecast(data);
      final backendAlert = '${data['alerta_clima'] ?? ''}'.trim();
      final temperatureC = _asDouble(current['temperatura_celsius']) ?? 0;
      final feelsLikeC = _asDouble(current['sensacao_termica']) ?? temperatureC;
      final humidity = _asInt(current['umidade_relativa']) ?? 0;
      final precipitationMm = _asDouble(current['precipitacao']) ?? 0;
      final chanceOfRain = _asInt(forecast['precipitacao_probabilidade']) ?? 0;
      final windKph = (_asDouble(current['velocidade_vento']) ?? 0) * 3.6;
      final city =
          '${localizacao['municipio'] ?? localizacao['cidade'] ?? location['municipio'] ?? 'Sua região'}';
      final region = '${localizacao['estado'] ?? location['estado'] ?? ''}';

      return WeatherModel(
        city: city,
        region: region,
        temperatureC: temperatureC,
        feelsLikeC: feelsLikeC == 0 ? temperatureC : feelsLikeC,
        humidity: humidity,
        precipitationMm: precipitationMm,
        chanceOfRain: chanceOfRain,
        condition:
            '${current['descricao'] ?? current['condicao'] ?? 'Sem atualização'}',
        windKph: windKph,
        agriculturalRecommendation: _buildRecommendation(
          backendAlert: backendAlert,
          dryRisk: _asDouble(data['indice_risco_seca']) ?? 0,
          temperatureC: temperatureC,
          humidity: humidity,
          precipitationMm: precipitationMm,
          chanceOfRain: chanceOfRain,
          windKph: windKph,
        ),
        fetchedAt: DateTime.now(),
      );
    } on WeatherException {
      rethrow;
    } on ApiException catch (exc, stackTrace) {
      debugPrint(
        'WeatherService.getWeatherBySensor ApiException: ${exc.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      throw WeatherException(exc.message);
    } catch (exc, stackTrace) {
      debugPrint('WeatherService.getWeatherBySensor unexpected error: $exc');
      debugPrintStack(stackTrace: stackTrace);
      throw const WeatherException('Não foi possível consultar o clima agora.');
    }
  }

  Map<String, dynamic> _firstForecast(Map<String, dynamic> data) {
    final forecast = data['previsao_proximas_horas'];
    if (forecast is List && forecast.isNotEmpty) {
      final first = forecast.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }
    return const {};
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
      return 'Há risco elevado de seca para esta área.';
    }
    if (chanceOfRain >= 60 || precipitationMm >= 3) {
      return 'Evite pulverização hoje.';
    }
    if (temperatureC >= 32) {
      return 'Priorize irrigação no início da manhã ou fim da tarde.';
    }
    if (humidity <= 35) {
      return 'Atenção ao estresse hídrico da cultura.';
    }
    if (windKph >= 22) {
      return 'Revise operações sensíveis ao vento antes de aplicar insumos.';
    }
    return 'Condições estáveis para manejo, com monitoramento ao longo do dia.';
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }

  int? _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }
}

class WeatherException implements Exception {
  const WeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}
