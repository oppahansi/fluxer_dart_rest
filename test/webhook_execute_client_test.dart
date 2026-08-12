import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  group('WebhookExecuteClient', () {
    late MockHttpTransport transport;
    late WebhookExecuteClient client;

    setUp(() {
      transport = MockHttpTransport();
      client = WebhookExecuteClient(transport: transport);
    });

    test(
      'execute posts to /webhooks/id/token with no Authorization header',
      () async {
        when(() => transport.send(any())).thenAnswer(
          (_) async => const HttpTransportResponse(
            statusCode: 200,
            headers: {},
            body: '',
          ),
        );

        await client.execute(
          Snowflake.parse('1'),
          'secret',
          content: 'hi',
          username: 'Announcer',
        );

        final captured =
            verify(() => transport.send(captureAny())).captured.single
                as HttpTransportRequest;
        expect(captured.method, 'POST');
        expect(captured.path, '/webhooks/1/secret');
        expect(captured.body, {'content': 'hi', 'username': 'Announcer'});
        expect(captured.headers.containsKey('Authorization'), isFalse);
      },
    );

    test('execute throws FluxerApiException on a 4xx response', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 404,
          headers: {},
          body: '{"code": "UNKNOWN_WEBHOOK", "message": "Unknown webhook"}',
        ),
      );

      await expectLater(
        () => client.execute(Snowflake.parse('1'), 'bad-token', content: 'hi'),
        throwsA(
          isA<FluxerApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.errorCode, 'errorCode', 'UNKNOWN_WEBHOOK'),
        ),
      );
    });
  });
}
