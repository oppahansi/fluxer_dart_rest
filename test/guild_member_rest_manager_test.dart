import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _sampleMemberJson =
    '{"user": {"id": "3", "username": "oppa", "discriminator": "0", "global_name": null, '
    '"avatar": null, "avatar_color": null, "bot": false, "system": false}, "nick": null, '
    '"avatar": null, "roles": [], "joined_at": "2026-08-11T12:00:00.000Z", "mute": false, "deaf": false, '
    '"communication_disabled_until": null}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  group('GuildMemberRestManager', () {
    late MockHttpTransport transport;
    late GuildMemberRestManager manager;

    setUp(() {
      transport = MockHttpTransport();
      manager = GuildMemberRestManager(
        RestClient(token: 't', transport: transport),
      );
    });

    test('list decodes an array of members', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: '[$_sampleMemberJson]',
        ),
      );

      final members = await manager.list(Snowflake.parse('1'));

      expect(members, hasLength(1));
      expect(members.single.user.username, 'oppa');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.path, '/guilds/1/members');
    });

    test('get fetches a single member', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: _sampleMemberJson,
        ),
      );

      final member = await manager.get(
        Snowflake.parse('1'),
        Snowflake.parse('3'),
      );

      expect(member.user.id, Snowflake.parse('3'));
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.path, '/guilds/1/members/3');
    });

    test('kick sends a DELETE to the member route', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );

      await manager.kick(Snowflake.parse('1'), Snowflake.parse('3'));

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'DELETE');
      expect(captured.path, '/guilds/1/members/3');
    });
  });
}
