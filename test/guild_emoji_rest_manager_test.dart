import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  test('GuildEmojiRestManager.list decodes an array of emojis', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body: '[{"id": "1", "name": "blob", "animated": false, "nsfw": false}]',
      ),
    );
    final manager = GuildEmojiRestManager(
      RestClient(token: 't', transport: transport),
    );

    final emojis = await manager.list(Snowflake.parse('1'));

    expect(emojis, hasLength(1));
    expect(emojis.single.name, 'blob');
    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.path, '/guilds/1/emojis');
  });

  test('GuildEmojiRestManager.create posts name/image', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body: '{"id": "1", "name": "blob", "animated": false, "nsfw": false}',
      ),
    );
    final manager = GuildEmojiRestManager(
      RestClient(token: 't', transport: transport),
    );

    final emoji = await manager.create(
      Snowflake.parse('1'),
      name: 'blob',
      image: 'data:image/png;base64,AAAA',
    );

    expect(emoji.name, 'blob');
    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'POST');
    expect(captured.path, '/guilds/1/emojis');
    expect(captured.body, {
      'name': 'blob',
      'image': 'data:image/png;base64,AAAA',
    });
  });

  test('GuildEmojiRestManager.clone posts the source emoji id', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body: '{"id": "2", "name": "blob", "animated": false, "nsfw": false}',
      ),
    );
    final manager = GuildEmojiRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.clone(Snowflake.parse('1'), Snowflake.parse('9'));

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.path, '/guilds/1/emojis/clone');
    expect(captured.body, {'source_emoji_id': '9'});
  });

  test('GuildEmojiRestManager.delete sends a DELETE', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async =>
          const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
    );
    final manager = GuildEmojiRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.delete(Snowflake.parse('1'), Snowflake.parse('9'));

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'DELETE');
    expect(captured.path, '/guilds/1/emojis/9');
  });
}
