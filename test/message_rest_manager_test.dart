import 'package:fluxer_core/fluxer_core.dart';
import 'package:fluxer_rest/fluxer_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  test(
    'MessageRestManager.send posts the built payload and decodes the response',
    () async {
      final transport = MockHttpTransport();
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 200,
          headers: {},
          body:
              '{"id": "1", "channel_id": "2", "author": {"id": "3", "username": "bot", "discriminator": "0", '
              '"global_name": null, "avatar": null, "avatar_color": null, "bot": true, "system": false}, '
              '"type": 0, "flags": 0, "content": "pong", "timestamp": "2026-08-11T12:00:00.000Z", '
              '"edited_timestamp": null, "pinned": false, "mention_everyone": false, "tts": false, '
              '"mentions": [], "mention_roles": []}',
        ),
      );
      final manager = MessageRestManager(
        RestClient(token: 't', transport: transport),
      );

      final message = await manager.send(
        Snowflake.parse('2'),
        MessageBuilder(content: 'pong'),
      );

      expect(message.content, 'pong');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'POST');
      expect(captured.path, '/channels/2/messages');
      expect(captured.body, {'content': 'pong'});
    },
  );
}
