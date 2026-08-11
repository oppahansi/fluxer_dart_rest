import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  test('MessageRestManager.list decodes an array of messages', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body:
            '[{"id": "1", "channel_id": "2", "author": {"id": "3", "username": "bot", "discriminator": "0", '
            '"global_name": null, "avatar": null, "avatar_color": null, "bot": true, "system": false}, '
            '"type": 0, "flags": 0, "content": "hi", "timestamp": "2026-08-11T12:00:00.000Z", '
            '"edited_timestamp": null, "pinned": false, "mention_everyone": false, "tts": false, '
            '"mentions": [], "mention_roles": []}]',
      ),
    );
    final manager = MessageRestManager(
      RestClient(token: 't', transport: transport),
    );

    final messages = await manager.list(Snowflake.parse('2'), limit: 10);

    expect(messages, hasLength(1));
    expect(messages.single.content, 'hi');
    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.path, '/channels/2/messages?limit=10');
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

  test('MessageRestManager.delete sends a DELETE to the message', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async =>
          const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
    );
    final manager = MessageRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.delete(Snowflake.parse('2'), Snowflake.parse('5'));

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'DELETE');
    expect(captured.path, '/channels/2/messages/5');
  });

  test('MessageRestManager.bulkDelete posts the message id list', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async =>
          const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
    );
    final manager = MessageRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.bulkDelete(Snowflake.parse('2'), [
      Snowflake.parse('5'),
      Snowflake.parse('6'),
    ]);

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'POST');
    expect(captured.path, '/channels/2/messages/bulk-delete');
    expect(captured.body, {
      'message_ids': ['5', '6'],
    });
  });

  test(
    'MessageRestManager.addReaction PUTs to the emoji reaction endpoint, URL-encoded',
    () async {
      final transport = MockHttpTransport();
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );
      final manager = MessageRestManager(
        RestClient(token: 't', transport: transport),
      );

      await manager.addReaction(
        Snowflake.parse('2'),
        Snowflake.parse('5'),
        '👍',
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'PUT');
      expect(
        captured.path,
        '/channels/2/messages/5/reactions/${Uri.encodeComponent('👍')}/@me',
      );
    },
  );
}
