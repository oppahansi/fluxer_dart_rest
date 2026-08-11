import 'package:fluxer_core/fluxer_core.dart';
import 'package:fluxer_rest/fluxer_rest.dart';
import 'package:fluxer_utils/fluxer_utils.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

HttpTransportResponse _jsonResponse(
  int statusCode,
  Object body, {
  Map<String, String> headers = const {},
}) => HttpTransportResponse(
  statusCode: statusCode,
  headers: headers,
  body: body.toString(),
);

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  group('RestClient', () {
    late MockHttpTransport transport;
    late RestClient client;

    setUp(() {
      transport = MockHttpTransport();
      client = RestClient(
        token: 'test-token',
        transport: transport,
        retryPolicy: ExponentialBackoffRetryPolicy(
          maxAttempts: 2,
          baseDelay: Duration.zero,
          jitterFraction: 0,
        ),
      );
    });

    test(
      'sends the Authorization header in Fluxer\'s Bot token format',
      () async {
        when(() => transport.send(any())).thenAnswer(
          (_) async => _jsonResponse(
            200,
            '{"id": "1", "name": "Test", "icon": null, "owner_id": "2"}',
          ),
        );

        await client.requestJson(method: 'GET', path: '/guilds/1');

        final captured =
            verify(() => transport.send(captureAny())).captured.single
                as HttpTransportRequest;
        expect(captured.headers['Authorization'], 'Bot test-token');
        expect(captured.method, 'GET');
        expect(captured.path, '/guilds/1');
      },
    );

    test('decodes a JSON body on success', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => _jsonResponse(200, '{"id": "1", "name": "Test"}'),
      );

      final json = await client.requestJson(method: 'GET', path: '/guilds/1');
      expect(json, {'id': '1', 'name': 'Test'});
    });

    test('returns null for an empty body', () async {
      when(
        () => transport.send(any()),
      ).thenAnswer((_) async => _jsonResponse(204, ''));

      final json = await client.requestJson(
        method: 'DELETE',
        path: '/guilds/1',
      );
      expect(json, isNull);
    });

    test(
      'throws FluxerApiException on a 4xx response, surfacing the error code and message',
      () async {
        when(() => transport.send(any())).thenAnswer(
          (_) async => _jsonResponse(
            404,
            '{"code": "UNKNOWN_GUILD", "message": "Unknown guild"}',
          ),
        );

        await expectLater(
          client.requestJson(method: 'GET', path: '/guilds/999'),
          throwsA(
            isA<FluxerApiException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.errorCode, 'errorCode', 'UNKNOWN_GUILD'),
          ),
        );
      },
    );

    test('retries a 5xx response and succeeds on the next attempt', () async {
      var callCount = 0;
      when(() => transport.send(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return _jsonResponse(503, '');
        return _jsonResponse(200, '{"id": "1"}');
      });

      final json = await client.requestJson(method: 'GET', path: '/guilds/1');
      expect(json, {'id': '1'});
      expect(callCount, 2);
    });

    test('honors Retry-After on a 429 and retries', () async {
      var callCount = 0;
      when(() => transport.send(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return _jsonResponse(
            429,
            '{"code": "RATE_LIMITED"}',
            headers: {'retry-after': '0'},
          );
        }
        return _jsonResponse(200, '{"id": "1"}');
      });

      final json = await client.requestJson(method: 'GET', path: '/guilds/1');
      expect(json, {'id': '1'});
      expect(callCount, 2);
    });

    test('gives up after retryPolicy.maxAttempts and throws', () async {
      when(
        () => transport.send(any()),
      ).thenAnswer((_) async => _jsonResponse(503, ''));

      await expectLater(
        client.requestJson(method: 'GET', path: '/guilds/1'),
        throwsA(
          isA<FluxerApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });
  });
}
