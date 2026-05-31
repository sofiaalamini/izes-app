import 'package:flutter/foundation.dart';

import '../config/backend_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AiAssistantService {
  AiAssistantService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String> answerQuestion(String question, {String? sensorId}) async {
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

    try {
      final queryParameters = <String, String>{
        'cliente_id': clientId,
        'pergunta': question.trim(),
      };
      if (sensorId != null && sensorId.trim().isNotEmpty) {
        queryParameters['sensor_id'] = sensorId.trim();
      }

      final data = await _apiClient.postJson(
        '/api/ia/chat',
        useAppToken: true,
        queryParameters: queryParameters,
        debugLabel: 'IA chat',
      );

      final reply = '${data['resposta_texto'] ?? ''}'.trim();
      if (reply.isNotEmpty) {
        return reply;
      }

      final fallbackReply = '${data['resposta'] ?? ''}'.trim();
      if (fallbackReply.isNotEmpty) {
        return fallbackReply;
      }

      return 'Nao consegui gerar uma resposta agora.';
    } on ApiException catch (error) {
      debugPrint('IA chat error: $error');
      if (error.message.contains('HTTP 401')) {
        throw const AiAssistantException(
          'Sua sessao expirou ou o token do app esta invalido.',
        );
      }
      throw const AiAssistantException(
        'Nao foi possivel consultar a IA agora.',
      );
    } catch (error, stackTrace) {
      debugPrint('IA chat unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const AiAssistantException(
        'Nao foi possivel consultar a IA agora.',
      );
    }
  }

  Future<String> analyzeImage(
    String imagePath, {
    String? message,
    String? sensorId,
  }) async {
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

    try {
      final fields = <String, String>{'cliente_id': clientId};
      final trimmedMessage = message?.trim() ?? '';
      if (trimmedMessage.isNotEmpty) {
        fields['mensagem'] = trimmedMessage;
      }
      if (sensorId != null && sensorId.trim().isNotEmpty) {
        fields['sensor_id'] = sensorId.trim();
      }

      debugPrint('IA multipart file field: imagem');
      if (trimmedMessage.isNotEmpty) {
        debugPrint('IA multipart text field: mensagem');
      }

      final data = await _apiClient.postMultipart(
        '/api/ia/analisar-imagem',
        useAppToken: true,
        fields: fields,
        fileField: 'imagem',
        filePath: imagePath,
        debugLabel: 'IA image',
      );

      final reply = '${data['resposta'] ?? data['resposta_texto'] ?? ''}'
          .trim();
      if (reply.isNotEmpty) {
        return reply;
      }

      return 'Nao consegui analisar a imagem agora.';
    } on ApiException catch (error) {
      debugPrint('IA image error: $error');
      if (error.message.contains('HTTP 401')) {
        throw const AiAssistantException(
          'Sua sessao expirou ou o token do app esta invalido.',
        );
      }
      throw const AiAssistantException(
        'Nao foi possivel analisar a imagem agora.',
      );
    } catch (error, stackTrace) {
      debugPrint('IA image unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const AiAssistantException(
        'Nao foi possivel analisar a imagem agora.',
      );
    }
  }
}

class AiAssistantException implements Exception {
  const AiAssistantException(this.message);

  final String message;

  @override
  String toString() => message;
}
