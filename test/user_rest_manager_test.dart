import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  group('UserRestManager', () {
    late MockHttpTransport transport;
    late UserRestManager manager;

    setUp(() {
      transport = MockHttpTransport();
      manager = UserRestManager(RestClient(token: 't', transport: transport));
    });

    test('createDm posts recipient_id and decodes a DmChannel', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 200,
          headers: {},
          body:
              '{"id": "5", "type": 1, "recipients": [{"id": "9"}], "last_message_id": null}',
        ),
      );

      final channel = await manager.createDm(Snowflake.parse('9'));

      expect(channel, isA<DmChannel>());
      expect(channel.id, Snowflake.parse('5'));
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'POST');
      expect(captured.path, '/v1/users/@me/channels');
      expect(captured.body, {'recipient_id': '9'});
    });
  });
}
