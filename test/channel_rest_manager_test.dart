import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  test('ChannelRestManager.get fetches and decodes a channel', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body:
            '{"id": "1", "type": 0, "name": "general", "guild_id": "2", "topic": null, '
            '"position": 0, "parent_id": null, "last_message_id": null, "nsfw": false, "rate_limit_per_user": 0}',
      ),
    );
    final manager = ChannelRestManager(
      RestClient(token: 't', transport: transport),
    );

    final channel = await manager.get(Snowflake.parse('1'));

    expect(channel, isA<GuildTextChannel>());
    expect((channel as GuildTextChannel).name, 'general');
    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.path, '/channels/1');
  });
}
