import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

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
        'Cliente não configurado para usar o assistente.',
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
        authenticated: true,
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

      return 'Não consegui gerar uma resposta agora.';
    } on ApiException catch (error) {
      debugPrint('IA chat error: $error');
      throw AiAssistantException(
        error.statusCode == null || error.statusCode! >= 500
            ? 'Não foi possível consultar a IA agora.'
            : error.friendlyMessage,
      );
    } catch (error, stackTrace) {
      debugPrint('IA chat unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const AiAssistantException(
        'Não foi possível consultar a IA agora.',
      );
    }
  }

  Future<String> analyzeImage(
    String imagePath, {
    List<int>? imageBytes,
    String? fileName,
    String? message,
    String? sensorId,
  }) async {
    final clientId = AuthService().resolvedClientId;
    if (clientId.isEmpty) {
      throw const AiAssistantException(
        'Cliente não configurado para usar o assistente.',
      );
    }

    try {
      final fields = <String, String>{
        'cliente_id': clientId,
        if (message != null && message.trim().isNotEmpty)
          'mensagem': message.trim(),
      };
      if (sensorId != null && sensorId.trim().isNotEmpty) {
        fields['sensor_id'] = sensorId.trim();
      }

      debugPrint('IA multipart file field: imagem');
      debugPrint('IA image path: $imagePath');
      debugPrint('IA image filename: ${fileName ?? '(sem nome)'}');
      debugPrint('IA image bytes: ${imageBytes?.length ?? 0}');
      debugPrint('IA multipart text field: mensagem');

      final data = await _apiClient.postMultipart(
        '/api/ia/analisar-imagem',
        authenticated: true,
        fields: fields,
        fileField: 'imagem',
        filePath: imagePath,
        fileBytes: imageBytes ?? const <int>[],
        fileName: fileName,
        fileContentType: _resolveImageContentType(fileName),
        debugLabel: 'IA image',
      );

      final reply = '${data['resposta'] ?? ''}'.trim();
      if (reply.isNotEmpty) {
        return reply;
      }

      throw ApiException('Resposta do backend sem o campo "resposta": $data');
    } on ApiException catch (error) {
      debugPrint('IA image error: $error');
      if (error.statusCode == 503) {
        throw const AiAssistantException(
          'A análise de imagem não está disponível no momento.',
        );
      }
      throw AiAssistantException(error.friendlyMessage);
    } catch (error, stackTrace) {
      debugPrint('IA image unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const AiAssistantException(
        'Não foi possível analisar a imagem agora. Tente novamente.',
      );
    }
  }

  MediaType _resolveImageContentType(String? fileName) {
    final normalized = (fileName ?? '').toLowerCase();
    if (normalized.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    return MediaType('image', 'jpeg');
  }
}

class AiAssistantException implements Exception {
  const AiAssistantException(this.message);

  final String message;

  @override
  String toString() => message;
}
