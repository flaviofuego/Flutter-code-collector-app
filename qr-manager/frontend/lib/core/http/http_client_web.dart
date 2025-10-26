import 'package:http/http.dart' as http;

class HttpClient {
  // En web, necesitamos asegurarnos de que las peticiones incluyan credenciales
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    return await http.post(
      url,
      headers: mergedHeaders,
      body: body,
    );
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    return await http.get(
      url,
      headers: mergedHeaders,
    );
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    return await http.put(
      url,
      headers: mergedHeaders,
      body: body,
    );
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    return await http.delete(
      url,
      headers: mergedHeaders,
    );
  }
}
