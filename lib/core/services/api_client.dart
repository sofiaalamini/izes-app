import 'dart:convert';

import 'package:http/http.dart' as http;

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
  }) async {
    final response = await _client.post(
      _buildUri(path, queryParameters),
      headers: await _buildHeaders(
        useAppToken: useAppToken,
        authenticated: authenticated,
        sendJsonBody: body != null,
      ),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? fields,
    required String fileField,
    required String filePath,
    bool useAppToken = false,
    bool authenticated = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _buildUri(path, queryParameters),
    );
    request.headers.addAll(
      await _buildHeaders(
        useAppToken: useAppToken,
        authenticated: authenticated,
      ),
    );
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
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
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
