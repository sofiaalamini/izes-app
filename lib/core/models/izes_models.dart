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
  });

  final AlertLevel level;
  final String title;
  final String detail;
  final String? label;

  factory AlertItem.fromApiAlertas(Map<String, dynamic> json) {
    final severity = '${json['severidade'] ?? ''}'.toLowerCase();
    return AlertItem(
      level: switch (severity) {
        'critico' || 'alto' => AlertLevel.urgent,
        'medio' || 'médio' => AlertLevel.attention,
        _ => AlertLevel.ok,
      },
      title: '${json['parametro'] ?? 'Alerta'} em ${json['zona_id'] ?? json['sensor_id'] ?? 'area monitorada'}',
      detail:
          '${json['acao_descricao'] ?? json['mensagem_ia'] ?? 'Nenhum detalhe retornado pelo backend.'}',
      label: '${json['severidade'] ?? 'baixo'}',
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
