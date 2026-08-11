import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  test('GuildStickerRestManager.list decodes an array of stickers', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body:
            '[{"id": "1", "name": "wave", "description": "a wave", "tags": ["hi"], "animated": false, "nsfw": false}]',
      ),
    );
    final manager = GuildStickerRestManager(
      RestClient(token: 't', transport: transport),
    );

    final stickers = await manager.list(Snowflake.parse('1'));

    expect(stickers, hasLength(1));
    expect(stickers.single.name, 'wave');
    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.path, '/guilds/1/stickers');
  });

  test(
    'GuildStickerRestManager.create posts name/image and optional fields',
    () async {
      final transport = MockHttpTransport();
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 200,
          headers: {},
          body:
              '{"id": "1", "name": "wave", "description": "a wave", "tags": ["hi"], "animated": false, "nsfw": false}',
        ),
      );
      final manager = GuildStickerRestManager(
        RestClient(token: 't', transport: transport),
      );

      await manager.create(
        Snowflake.parse('1'),
        name: 'wave',
        image: 'data:image/png;base64,AAAA',
        description: 'a wave',
        tags: 'hi',
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'POST');
      expect(captured.path, '/guilds/1/stickers');
      expect(captured.body, {
        'name': 'wave',
        'image': 'data:image/png;base64,AAAA',
        'description': 'a wave',
        'tags': 'hi',
      });
    },
  );

  test('GuildStickerRestManager.clone posts the source sticker id', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body:
            '{"id": "2", "name": "wave", "description": "a wave", "tags": ["hi"], "animated": false, "nsfw": false}',
      ),
    );
    final manager = GuildStickerRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.clone(Snowflake.parse('1'), Snowflake.parse('9'));

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.path, '/guilds/1/stickers/clone');
    expect(captured.body, {'source_sticker_id': '9'});
  });

  test('GuildStickerRestManager.delete sends a DELETE', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async =>
          const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
    );
    final manager = GuildStickerRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.delete(Snowflake.parse('1'), Snowflake.parse('9'));

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'DELETE');
    expect(captured.path, '/guilds/1/stickers/9');
  });
}
