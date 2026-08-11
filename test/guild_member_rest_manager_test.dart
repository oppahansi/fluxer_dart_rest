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

    test(
      'list sends the default limit, since the server defaults to 1',
      () async {
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
        expect(captured.path, '/guilds/1/members?limit=100');
      },
    );

    test('list forwards an explicit limit and after cursor', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: '[$_sampleMemberJson]',
        ),
      );

      await manager.list(
        Snowflake.parse('1'),
        limit: 5,
        after: Snowflake.parse('9'),
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.path, '/guilds/1/members?limit=5&after=9');
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

    test('timeout PATCHes communication_disabled_until', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: _sampleMemberJson,
        ),
      );
      final until = DateTime.utc(2026, 1, 1);

      await manager.timeout(
        Snowflake.parse('1'),
        Snowflake.parse('3'),
        until: until,
        reason: 'spamming',
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'PATCH');
      expect(captured.path, '/guilds/1/members/3');
      expect(captured.body, {
        'communication_disabled_until': until.toIso8601String(),
        'timeout_reason': 'spamming',
      });
    });

    test('timeout with until: null omits timeout_reason when unset', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: _sampleMemberJson,
        ),
      );

      await manager.timeout(
        Snowflake.parse('1'),
        Snowflake.parse('3'),
        until: null,
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.body, {'communication_disabled_until': null});
    });

    test('addRole PUTs to the member role route', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );

      await manager.addRole(
        Snowflake.parse('1'),
        Snowflake.parse('3'),
        Snowflake.parse('9'),
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'PUT');
      expect(captured.path, '/guilds/1/members/3/roles/9');
    });

    test('removeRole DELETEs the member role route', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );

      await manager.removeRole(
        Snowflake.parse('1'),
        Snowflake.parse('3'),
        Snowflake.parse('9'),
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'DELETE');
      expect(captured.path, '/guilds/1/members/3/roles/9');
    });
  });
}
