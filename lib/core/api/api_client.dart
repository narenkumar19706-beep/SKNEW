import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    SecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? SecureStorage(),
        _client = client ?? http.Client();

  final String baseUrl;
  final SecureStorage _storage;
  final http.Client _client;

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.trim();
    final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: decoded is Map<String, dynamic> && decoded['error'] != null
          ? decoded['error'].toString()
          : 'Request failed',
      data: decoded is Map<String, dynamic> ? decoded : null,
    );
  }
}
