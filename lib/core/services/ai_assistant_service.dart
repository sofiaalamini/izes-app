import '../config/backend_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AiAssistantService {
  AiAssistantService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String> answerQuestion(String question) async {
    final clientId = AuthService().resolvedClientId;
    if (clientId.isEmpty) {
      throw const AiAssistantException(
        'Cliente nao configurado para usar o assistente.',
      );
    }
    if (!BackendConfig.hasAppToken) {
      throw const AiAssistantException(
        'API_APP_TOKEN nao configurado no .env.',
      );
    }

    final data = await _apiClient.postJson(
      '/api/ia/chat',
      useAppToken: true,
      queryParameters: {
        'cliente_id': clientId,
        'pergunta': question.trim(),
      },
    );

    final reply = <String>[
      '${data['resposta_texto'] ?? ''}'.trim(),
      if (data['recomendacao'] is Map<String, dynamic>)
        'Acao: ${((data['recomendacao'] as Map<String, dynamic>)['acao'] ?? '').toString().trim()}',
      if (data['atencoes'] is List && (data['atencoes'] as List).isNotEmpty)
        'Atencoes: ${(data['atencoes'] as List).join(', ')}',
      if (data['proximos_passos'] is List &&
          (data['proximos_passos'] as List).isNotEmpty)
        'Proximos passos: ${(data['proximos_passos'] as List).join(', ')}',
    ].where((item) => item.isNotEmpty).join('\n\n');

    if (reply.isEmpty) {
      throw const AiAssistantException(
        'Backend nao retornou uma resposta valida da IA.',
      );
    }

    return reply;
  }
}

class AiAssistantException implements Exception {
  const AiAssistantException(this.message);

  final String message;

  @override
  String toString() => message;
}
