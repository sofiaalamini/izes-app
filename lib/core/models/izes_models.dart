import 'dart:typed_data';

enum AlertLevel { urgent, attention, ok }

class DashboardSummary {
  const DashboardSummary({
    required this.urgentCount,
    required this.attentionCount,
    required this.okCount,
    required this.sensorCount,
  });

  final int urgentCount;
  final int attentionCount;
  final int okCount;
  final int sensorCount;
}

class AlertItem {
  const AlertItem({
    required this.level,
    required this.title,
    required this.detail,
    this.label,
    this.sensorName,
    this.location,
    this.temperature,
    this.humidity,
    this.ph,
    this.problem,
    this.recommendation,
  });

  final AlertLevel level;
  final String title;
  final String detail;
  final String? label;
  final String? sensorName;
  final String? location;
  final String? temperature;
  final String? humidity;
  final String? ph;

  /// Texto do problema vindo do motor de regras do backend, quando houver.
  final String? problem;

  /// Ação recomendada vinda do motor de regras do backend, quando houver.
  final String? recommendation;

  /// Leitura mais antiga que isso indica sensor parado/sem comunicação.
  static const staleAfter = Duration(hours: 24);

  static bool isStale(Map<String, dynamic> sensor) {
    final reading = sensor['ultima_leitura'] as Map<String, dynamic>?;
    final timestamp = DateTime.tryParse('${reading?['timestamp'] ?? ''}');
    if (timestamp == null) return true;
    return DateTime.now().toUtc().difference(timestamp.toUtc()) > staleAfter;
  }

  static List<Map<String, dynamic>> activeAlerts(Map<String, dynamic> sensor) {
    return (sensor['alertas'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  factory AlertItem.fromDashboardSensor(Map<String, dynamic> sensor) {
    final reading =
        sensor['ultima_leitura'] as Map<String, dynamic>? ?? const {};
    final alerts = activeAlerts(sensor);
    final stale = isStale(sensor);
    final critical =
        reading['nivel_critico'] == true ||
        alerts.any((alert) => alert['severidade'] == 'critico');
    final active = reading['alerta_ativo'] == true || alerts.isNotEmpty || stale;
    final title = '${sensor['nome'] ?? sensor['sensor_id'] ?? 'Sensor'}';
    final property = '${sensor['propriedade'] ?? ''}'.trim();
    final city = '${sensor['municipio'] ?? ''}'.trim();
    final state = '${sensor['estado'] ?? ''}'.trim();
    final local = [
      if (property.isNotEmpty) property,
      if (city.isNotEmpty || state.isNotEmpty)
        [city, state].where((value) => value.isNotEmpty).join('/'),
    ].join(' • ');
    final values = <String>[
      if (reading['temperatura'] != null) 'Temp. ${reading['temperatura']} C',
      if (reading['umidade'] != null) 'Umidade ${reading['umidade']}%',
      if (reading['ph'] != null) 'pH ${reading['ph']}',
    ].join(' • ');

    return AlertItem(
      level: critical
          ? AlertLevel.urgent
          : active
          ? AlertLevel.attention
          : AlertLevel.ok,
      title: title,
      detail: values.isEmpty
          ? 'Revise esta leitura em $local.'
          : '$values em $local.',
      label: critical
          ? 'Urgente'
          : active
          ? 'Atenção'
          : 'Estável',
      sensorName: title,
      location: local.isEmpty ? 'Área monitorada' : local,
      temperature: reading['temperatura'] == null
          ? null
          : '${reading['temperatura']} C',
      humidity: reading['umidade'] == null ? null : '${reading['umidade']}%',
      ph: reading['ph'] == null ? null : '${reading['ph']}',
      problem: stale
          ? _staleProblem(reading['timestamp'])
          : alerts.isEmpty
          ? null
          : '${alerts.first['titulo'] ?? ''}. ${alerts.first['mensagem'] ?? ''}'
                .trim(),
      recommendation: stale
          ? 'Verifique conexão, energia ou bateria do sensor no campo.'
          : alerts.isEmpty
          ? null
          : [
              '${alerts.first['recomendacao'] ?? ''}'.trim(),
              if (alerts.length > 1)
                '+${alerts.length - 1} alerta(s) neste sensor.',
            ].where((text) => text.isNotEmpty).join(' • '),
    );
  }

  static String _staleProblem(dynamic timestamp) {
    final parsed = DateTime.tryParse('${timestamp ?? ''}');
    if (parsed == null) {
      return 'Sensor instalado, mas ainda não enviou nenhuma leitura.';
    }
    final hours = DateTime.now().toUtc().difference(parsed.toUtc()).inHours;
    final since = hours >= 48 ? '${hours ~/ 24} dias' : '$hours horas';
    return 'Sem comunicação: última leitura há $since.';
  }

  factory AlertItem.fromApiAlertas(Map<String, dynamic> json) {
    final severity = '${json['severidade'] ?? ''}'.toLowerCase();
    final parametro = '${json['parametro'] ?? 'Manejo'}'.trim();
    final local = '${json['zona_id'] ?? json['sensor_id'] ?? 'área monitorada'}'
        .trim();
    return AlertItem(
      level: switch (severity) {
        'critico' || 'crítico' || 'alto' => AlertLevel.urgent,
        'medio' || 'médio' || 'mÃ©dio' => AlertLevel.attention,
        _ => AlertLevel.ok,
      },
      title: '$parametro em $local',
      detail:
          '${json['acao_descricao'] ?? json['mensagem_ia'] ?? 'Acompanhe a área e confira a próxima leitura.'}',
      label: '${json['severidade'] ?? 'baixo'}',
      sensorName: '${json['sensor_id'] ?? parametro}',
      location: local,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.imageBytes,
  });

  final String text;
  final bool isUser;
  final Uint8List? imageBytes;
}
