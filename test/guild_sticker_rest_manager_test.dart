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
}
