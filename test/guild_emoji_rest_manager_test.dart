import 'package:fluxer_core/fluxer_core.dart';
import 'package:fluxer_rest/fluxer_rest.dart';
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
}
