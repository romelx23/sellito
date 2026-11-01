import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status;
  final String message;

  ApiException(this.status, this.message);

  bool get isNetwork => status == 0;

  @override
  String toString() => message;
}

class Api {
  static const _override = String.fromEnvironment('API_URL');
  static const _sameOrigin = bool.fromEnvironment('SAME_ORIGIN');

  static String get baseUrl {
    if (_sameOrigin) return '';
    if (_override.isNotEmpty) return _override.replaceAll(RegExp(r'/$'), '');
    // Un build de release sin servidor propio no debe apuntar a localhost.
    if (kReleaseMode && !kIsWeb) {
      throw StateError('Falta --dart-define=API_URL=https://tu-servidor en el build de release.');
    }
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String get siteUrl {
    if (_sameOrigin) {
      final origin = Uri.base.origin;
      return origin == 'null' ? '' : origin;
    }
    return baseUrl;
  }

  String? token;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> get(String path) {
    return _send(() => http.get(_uri(path), headers: _headers));
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) {
    return _send(
      () => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? const {})),
    );
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) {
    return _send(
      () => http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? const {})),
    );
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send(() => http.delete(_uri(path), headers: _headers));
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() run) async {
    http.Response response;
    try {
      response = await run().timeout(const Duration(seconds: 25));
    } catch (_) {
      throw ApiException(
        0,
        'No pudimos conectar con el servidor. Revisá que el backend esté corriendo.',
      );
    }

    final raw = utf8.decode(response.bodyBytes);
    Map<String, dynamic> data = const {};
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {
        // Respuesta no JSON (por ejemplo un HTML de error).
      }
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        data['error'] as String? ?? 'Error ${response.statusCode}',
      );
    }

    return data;
  }
}
