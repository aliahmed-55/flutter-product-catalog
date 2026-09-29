import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_catalog/core/network/api_client.dart';
import 'package:product_catalog/core/network/api_exception.dart';

void main() {
  test('ClientException uses a server and connection message', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => throw http.ClientException('Unreachable host'),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      client.get('/products'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Unable to reach the server. Please check your connection and try again.',
        ),
      ),
    );
  });

  test('Timeout retains its distinct message', () async {
    final client = ApiClient(
      client: MockClient((_) async => throw TimeoutException('Timeout')),
    );
    addTearDown(client.close);
    await expectLater(
      client.get('/products'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'The request timed out. Please try again.',
        ),
      ),
    );
  });

  test('Malformed JSON is an invalid-data error', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('invalid JSON', 200)),
    );
    addTearDown(client.close);
    await expectLater(
      client.get('/products'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'The server returned invalid data. Please try again.',
        ),
      ),
    );
  });

  for (final entry in {
    404: 'The requested data could not be found.',
    429: 'Too many requests. Please try again shortly.',
    503: 'The server is unavailable. Please try again later.',
  }.entries) {
    test('HTTP ${entry.key} retains its status-specific error', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          expect(request.url.host, 'dummyjson.com');
          return http.Response('Server response', entry.key);
        }),
      );
      addTearDown(client.close);
      await expectLater(
        client.get('/products-invalid'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            entry.value,
          ),
        ),
      );
    });
  }
}
