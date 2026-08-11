import 'package:fluxer_core/fluxer_core.dart';
import 'package:fluxer_rest/fluxer_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _sampleInviteJson =
    '{"code": "abc123", "type": 0, "guild": {"id": "1", "name": "Test Guild"}, '
    '"channel": {"id": "2", "name": "general", "type": 0, "recipients": []}, "inviter": null, '
    '"member_count": 5, "presence_count": 2, "expires_at": null, "temporary": false}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  group('InviteRestManager', () {
    late MockHttpTransport transport;
    late InviteRestManager manager;

    setUp(() {
      transport = MockHttpTransport();
      manager = InviteRestManager(RestClient(token: 't', transport: transport));
    });

    test('listForGuild decodes an array of invites', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: '[$_sampleInviteJson]',
        ),
      );

      final invites = await manager.listForGuild(Snowflake.parse('1'));

      expect(invites, hasLength(1));
      expect(invites.single.code, 'abc123');
    });

    test('get fetches a single invite by code', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 200,
          headers: {},
          body: _sampleInviteJson,
        ),
      );

      final invite = await manager.get('abc123');

      expect(invite.code, 'abc123');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.path, '/invites/abc123');
    });

    test(
      'createForChannel only includes explicitly-set fields in the body',
      () async {
        when(() => transport.send(any())).thenAnswer(
          (_) async => const HttpTransportResponse(
            statusCode: 200,
            headers: {},
            body: _sampleInviteJson,
          ),
        );

        await manager.createForChannel(Snowflake.parse('2'), maxUses: 5);

        final captured =
            verify(() => transport.send(captureAny())).captured.single
                as HttpTransportRequest;
        expect(captured.method, 'POST');
        expect(captured.path, '/channels/2/invites');
        expect(captured.body, {'max_uses': 5});
      },
    );

    test('delete sends a DELETE to the invite route', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );

      await manager.delete('abc123');

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'DELETE');
      expect(captured.path, '/invites/abc123');
    });
  });
}
