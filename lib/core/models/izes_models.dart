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

  factory AlertItem.fromDashboardSensor(Map<String, dynamic> sensor) {
    final reading =
        sensor['ultima_leitura'] as Map<String, dynamic>? ?? const {};
    final critical = reading['nivel_critico'] == true;
    final active = reading['alerta_ativo'] == true;
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
    );
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
