import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 10)})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<Object> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}$path',
      ).replace(queryParameters: queryParameters);
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode == 404) {
        throw const ApiException('The requested data could not be found.');
      }
      if (response.statusCode == 429) {
        throw const ApiException(
          'Too many requests. Please try again shortly.',
        );
      }
      if (response.statusCode >= 500) {
        throw const ApiException(
          'The server is unavailable. Please try again later.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiException('Unable to load data. Please try again.');
      }

      final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> && data is! List<dynamic>) {
        throw const ApiException(
          'The server returned unexpected data. Please try again.',
        );
      }
      return data!;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const ApiException(
        'Unable to connect. Check your internet connection and try again.',
      );
    } on FormatException {
      throw const ApiException(
        'The server returned invalid data. Please try again.',
      );
    } on Exception {
      throw const ApiException(
        'Unable to complete the request. Please try again.',
      );
    }
  }

  void close() => _client.close();
}
