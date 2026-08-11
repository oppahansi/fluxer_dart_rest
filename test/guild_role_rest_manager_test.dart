import 'package:fluxer_core/fluxer_core.dart';
import 'package:fluxer_rest/fluxer_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _sampleRoleJson =
    '{"id": "1", "name": "Moderator", "color": 0, "position": 1, "permissions": "0", "hoist": true, '
    '"mentionable": false, "unicode_emoji": null}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  group('GuildRoleRestManager', () {
    late MockHttpTransport transport;
    late GuildRoleRestManager manager;

    setUp(() {
      transport = MockHttpTransport();
      manager = GuildRoleRestManager(
        RestClient(token: 't', transport: transport),
      );
    });

    test('list decodes an array of roles', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: '[$_sampleRoleJson]',
        ),
      );

      final roles = await manager.list(Snowflake.parse('1'));

      expect(roles, hasLength(1));
      expect(roles.single.name, 'Moderator');
    });

    test(
      'create posts the name/color/permissions and decodes the response',
      () async {
        when(() => transport.send(any())).thenAnswer(
          (_) async => const HttpTransportResponse(
            statusCode: 200,
            headers: {},
            body: _sampleRoleJson,
          ),
        );

        final role = await manager.create(
          Snowflake.parse('1'),
          name: 'Moderator',
          color: 0,
          permissions: Permissions(PermissionFlag.kickMembers.bit),
        );

        expect(role.name, 'Moderator');
        final captured =
            verify(() => transport.send(captureAny())).captured.single
                as HttpTransportRequest;
        expect(captured.method, 'POST');
        expect(captured.path, '/guilds/1/roles');
        expect(captured.body, {
          'name': 'Moderator',
          'color': 0,
          'permissions': PermissionFlag.kickMembers.bit.toString(),
        });
      },
    );

    test('delete sends a DELETE to the role route', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );

      await manager.delete(Snowflake.parse('1'), Snowflake.parse('2'));

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'DELETE');
      expect(captured.path, '/guilds/1/roles/2');
    });
  });
}
