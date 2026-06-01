import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/backend_config.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient({http.Client? client, AuthService? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? AuthService();

  final http.Client _client;
  final AuthService _authService;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool useAppToken = false,
    bool authenticated = false,
  }) async {
    final response = await _client.get(
      _buildUri(path, queryParameters),
      headers: await _buildHeaders(
        useAppToken: useAppToken,
        authenticated: authenticated,
      ),
    );
    return _decodeMap(response);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? queryParameters,
    bool useAppToken = false,
    bool authenticated = false,
  }) async {
    final response = await _client.get(
      _buildUri(path, queryParameters),
      headers: await _buildHeaders(
        useAppToken: useAppToken,
        authenticated: authenticated,
      ),
    );
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
    bool useAppToken = false,
    bool authenticated = false,
    String? debugLabel,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _client.post(
      uri,
      headers: await _buildHeaders(
        useAppToken: useAppToken,
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
    bool useAppToken = false,
    bool authenticated = false,
    String? debugLabel,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final file = File(filePath);
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

    final fileExists = await file.exists();
    if (!fileExists && fileBytes.isEmpty) {
      throw ApiException(
        'Arquivo de imagem nao encontrado para upload: $filePath',
      );
    }
    if (debugLabel != null && debugLabel.isNotEmpty) {
      debugPrint('$debugLabel fileExistsOnDisk: $fileExists');
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
      await _buildHeaders(
        useAppToken: useAppToken,
        authenticated: authenticated,
      ),
    );
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
    required bool useAppToken,
    required bool authenticated,
    bool sendJsonBody = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (useAppToken && BackendConfig.hasAppToken) {
      headers['X-App-Token'] = BackendConfig.appToken;
    }

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
    throw const ApiException('Nao foi possivel carregar os dados agora.');
  }

  List<dynamic> _decodeList(http.Response response) {
    final dynamic data = _decode(response);
    if (data is List<dynamic>) {
      return data;
    }
    throw const ApiException('Nao foi possivel carregar os dados agora.');
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.trim();
      throw ApiException(
        'HTTP ${response.statusCode}: ${body.isEmpty ? 'Nao foi possivel concluir sua solicitacao.' : body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body);
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
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
