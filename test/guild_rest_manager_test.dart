import 'package:fluxer_core/fluxer_core.dart';
import 'package:fluxer_rest/fluxer_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  test('GuildRestManager.get fetches and decodes a guild', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body:
            '{"id": "1", "name": "Test Guild", "icon": null, "owner_id": "2", "member_count": 10}',
      ),
    );
    final manager = GuildRestManager(
      RestClient(token: 't', transport: transport),
    );

    final guild = await manager.get(Snowflake.parse('1'));

    expect(guild.name, 'Test Guild');
    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.path, '/guilds/1');
    expect(captured.method, 'GET');
  });
}
