import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/backend_config.dart';
import 'auth_service.dart';
import 'cache_service.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    AuthService? authService,
    CacheService? cache,
    Duration? timeout,
  }) : _cache = cache ?? CacheService(),
       _client = _TimeoutClient(
         client ?? http.Client(),
         timeout ?? _requestTimeout,
       ),
       _authService = authService ?? AuthService();

  /// Inclui chamadas à IA, que podem levar alguns segundos no backend.
  static const _requestTimeout = Duration(seconds: 75);

  final http.Client _client;
  final AuthService _authService;
  final CacheService _cache;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
    String? debugLabel,
    String? cacheKey,
  }) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final response = await _client.get(
        uri,
        headers: await _buildHeaders(authenticated: authenticated),
      );
      _logResponse(debugLabel, uri, response);
      final data = _decodeMap(response);
      if (cacheKey != null) {
        await _cache.save(cacheKey, data);
        _cache.markOnline();
      }
      return data;
    } catch (error) {
      // Sem conexão (ou servidor fora do ar): mostra a última resposta salva.
      final saved = cacheKey != null && _isConnectionProblem(error)
          ? await _cache.read(cacheKey)
          : null;
      if (saved == null) rethrow;
      _cache.markOffline(saved.savedAt);
      return saved.data;
    }
  }

  bool _isConnectionProblem(Object error) {
    if (error is http.ClientException) return true;
    if (error is! ApiException) return false;
    return error.semConexao ||
        error.statusCode == 502 ||
        error.statusCode == 503 ||
        error.statusCode == 504;
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
  }) async {
    final response = await _client.get(
      _buildUri(path, queryParameters),
      headers: await _buildHeaders(authenticated: authenticated),
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
    bool authenticated = false,
    String? debugLabel,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _client.post(
      uri,
      headers: await _buildHeaders(
        authenticated: authenticated,
        sendJsonBody: body != null,
      ),
      body: body == null ? null : jsonEncode(body),
    );
    _logResponse(debugLabel, uri, response);
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? fields,
    required String fileField,
    required String filePath,
    required List<int> fileBytes,
    String? fileName,
    MediaType? fileContentType,
    bool authenticated = false,
    String? debugLabel,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final resolvedFileName = (fileName == null || fileName.trim().isEmpty)
        ? _fallbackFileName(filePath)
        : fileName.trim();
    final resolvedContentType =
        fileContentType ?? _inferImageContentType(resolvedFileName);

    if (debugLabel != null && debugLabel.isNotEmpty) {
      debugPrint('$debugLabel URL: $uri');
      debugPrint('$debugLabel filePath: $filePath');
      debugPrint('$debugLabel fileName: $resolvedFileName');
      debugPrint('$debugLabel fileSizeBytes: ${fileBytes.length}');
      debugPrint('$debugLabel fileContentType: $resolvedContentType');
    }

    if (fileBytes.isEmpty) {
      throw ApiException(
        'Não foi possível ler a imagem selecionada para upload.',
      );
    }
    if (debugLabel != null && debugLabel.isNotEmpty) {
      debugPrint('$debugLabel fileReadyFromBytes: ${fileBytes.isNotEmpty}');
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _buildHeaders(authenticated: authenticated));
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: resolvedFileName,
        contentType: resolvedContentType,
      ),
    );

    if (debugLabel != null && debugLabel.isNotEmpty) {
      debugPrint('$debugLabel multipart field: $fileField');
      debugPrint('$debugLabel multipart fields: ${request.fields}');
      debugPrint(
        '$debugLabel multipart headers before send: ${request.headers}',
      );
      final multipartFile = request.files.last;
      debugPrint(
        '$debugLabel multipart file prepared: filename=${multipartFile.filename}, length=${multipartFile.length}, contentType=${multipartFile.contentType}',
      );
    }

    final streamedResponse = await _client.send(request);
    if (debugLabel != null && debugLabel.isNotEmpty) {
      debugPrint('$debugLabel multipart headers sent: ${request.headers}');
    }
    final response = await http.Response.fromStream(streamedResponse);
    _logResponse(debugLabel, uri, response);
    return _decodeMap(response);
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final base = Uri.parse('${BackendConfig.baseUrl}$path');
    return base.replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _buildHeaders({
    required bool authenticated,
    bool sendJsonBody = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (authenticated) {
      headers['Authorization'] =
          'Bearer ${await _authService.getAccessToken()}';
    }

    if (sendJsonBody) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final dynamic data = _decode(response);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const ApiException('Não foi possível carregar os dados agora.');
  }

  List<dynamic> _decodeList(http.Response response) {
    final dynamic data = _decode(response);
    if (data is List<dynamic>) {
      return data;
    }
    throw const ApiException('Não foi possível carregar os dados agora.');
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.trim();
      if (response.statusCode == 401) {
        // Token ausente, inválido ou expirado: volta para a tela de login.
        _authService.logout();
      }
      throw ApiException(
        'HTTP ${response.statusCode}: ${body.isEmpty ? 'Não foi possível concluir sua solicitação.' : body}',
        statusCode: response.statusCode,
        detail: _extractDetail(body),
      );
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body);
  }

  String? _extractDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        final detail = (decoded['detail'] as String).trim();
        return detail.isEmpty ? null : detail;
      }
    } catch (_) {}
    return null;
  }

  void _logResponse(String? debugLabel, Uri uri, http.Response response) {
    if (debugLabel == null || debugLabel.isEmpty) return;
    debugPrint('$debugLabel URL: $uri');
    debugPrint('$debugLabel statusCode: ${response.statusCode}');
    debugPrint('$debugLabel body: ${response.body}');
  }

  String _fallbackFileName(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final lastSegment = normalized.split('/').last.trim();
    if (lastSegment.isNotEmpty) {
      return lastSegment;
    }
    return 'upload.jpg';
  }

  MediaType _inferImageContentType(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (normalized.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (normalized.endsWith('.heic')) {
      return MediaType('image', 'heic');
    }
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return MediaType('image', 'jpeg');
  }
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.detail,
    this.semConexao = false,
  });

  /// Texto técnico (inclui o status HTTP); use [friendlyMessage] na interface.
  final String message;
  final int? statusCode;

  /// Campo `detail` da resposta do backend, quando houver.
  final String? detail;

  /// Verdadeiro quando não houve resposta do servidor (timeout, rede caída).
  final bool semConexao;

  /// Mensagem em português pronta para mostrar ao usuário.
  String get friendlyMessage {
    switch (statusCode) {
      case 401:
        return 'Sua sessão expirou. Entre novamente.';
      case 403:
        return 'Você não tem acesso a este recurso.';
      case 404:
        return 'Não encontramos o que você pediu.';
      case 413:
        return 'O arquivo é muito grande. Tente uma foto com menor resolução.';
      case 429:
        return 'Muitas solicitações em pouco tempo. Aguarde um instante e tente de novo.';
    }
    final code = statusCode;
    if (code != null && code >= 400 && code < 500 && detail != null) {
      return detail!;
    }
    if (code != null && code >= 500) {
      return 'O servidor está indisponível no momento. Tente novamente em instantes.';
    }
    return message;
  }

  @override
  String toString() => message;
}

class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final http.Client _inner;
  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner
        .send(request)
        .timeout(
          _timeout,
          onTimeout: () => throw const ApiException(
            'A conexão demorou demais. Verifique sua internet e tente novamente.',
            semConexao: true,
          ),
        );
  }
}
