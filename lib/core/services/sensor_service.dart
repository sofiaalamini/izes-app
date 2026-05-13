import '../config/backend_config.dart';
import '../models/sensor_model.dart';
import 'api_client.dart';

class SensorService {
  SensorService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<SensorModel>> fetchSensors() async {
    if (!BackendConfig.hasClientId) {
      throw const SensorServiceException(
        'API_CLIENT_ID nao configurado no .env.',
      );
    }

    final data = await _apiClient.getJson(
      '/api/dashboard/cliente/${BackendConfig.clientId}/sensores',
      useAppToken: true,
    );
    final sensors = (data['sensores'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return sensors.map(_mapSensor).toList();
  }

  SensorModel _mapSensor(Map<String, dynamic> sensor) {
    final reading =
        sensor['ultima_leitura'] as Map<String, dynamic>? ?? const {};
    final temperature = _asDouble(reading['temperatura']);
    final humidity = _asInt(reading['umidade']);
    final ph = _asDouble(reading['ph']);
    final property = '${sensor['propriedade'] ?? 'Propriedade'}';
    final city = '${sensor['municipio'] ?? 'Municipio'}';
    final state = '${sensor['estado'] ?? 'UF'}';
    final hasReading = reading['timestamp'] != null;

    final facts = <SensorFact>[
      if (humidity != null)
        SensorFact(label: 'Umidade', value: '${humidity.toString()}%'),
      if (temperature != null)
        SensorFact(label: 'Temperatura', value: '${temperature.toStringAsFixed(1)} C'),
      if (ph != null) SensorFact(label: 'pH', value: ph.toStringAsFixed(1)),
    ];

    return SensorModel(
      id: '${sensor['sensor_id']}',
      label: '${sensor['nome'] ?? sensor['sensor_id'] ?? 'Sensor'}',
      status: _statusFromReading(
        hasReading: hasReading,
        alertActive: reading['alerta_ativo'] == true,
        critical: reading['nivel_critico'] == true,
      ),
      lastReading: _parseDateTime(reading['timestamp']),
      note: '$property · $city/$state',
      primaryValue: facts.isEmpty ? 'Sem leitura' : facts.first.value,
      location: property,
      facts: facts,
    );
  }

  SensorStatus _statusFromReading({
    required bool hasReading,
    required bool alertActive,
    required bool critical,
  }) {
    if (!hasReading) {
      return SensorStatus.offline;
    }
    if (critical || alertActive) {
      return SensorStatus.attention;
    }
    return SensorStatus.online;
  }

  DateTime? _parseDateTime(dynamic value) {
    return DateTime.tryParse('$value');
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

class SensorServiceException implements Exception {
  const SensorServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
