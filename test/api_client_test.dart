import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_catalog/core/network/api_client.dart';
import 'package:product_catalog/core/network/api_exception.dart';

void main() {
  test('GET sends query parameters and decodes the JSON response', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'dummyjson.com');
        expect(request.url.path, '/products');
        expect(request.url.queryParameters, {'limit': '10', 'skip': '0'});
        return http.Response(
          '{"products":[],"total":0,"skip":0,"limit":10}',
          200,
        );
      }),
    );
    addTearDown(client.close);

    final data = await client.get(
      '/products',
      queryParameters: {'limit': '10', 'skip': '0'},
    );

    expect(data, {'products': [], 'total': 0, 'skip': 0, 'limit': 10});
  });

  test('HTTP 404 becomes a user-friendly API error', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('Not found', 404)),
    );
    addTearDown(client.close);

    await expectLater(
      client.get('/products-invalid'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'The requested data could not be found.',
        ),
      ),
    );
  });
}
