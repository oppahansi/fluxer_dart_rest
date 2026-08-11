import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
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

  test(
    'GuildRestManager.createChannel posts the built payload and decodes the response',
    () async {
      final transport = MockHttpTransport();
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 200,
          headers: {},
          body:
              '{"id": "3", "type": 0, "name": "general", "guild_id": "1", "topic": null, '
              '"position": 0, "parent_id": null, "last_message_id": null, "nsfw": false, "rate_limit_per_user": 0}',
        ),
      );
      final manager = GuildRestManager(
        RestClient(token: 't', transport: transport),
      );

      final channel = await manager.createChannel(
        Snowflake.parse('1'),
        ChannelCreateBuilder(name: 'general', type: ChannelType.guildText),
      );

      expect((channel as GuildTextChannel).name, 'general');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'POST');
      expect(captured.path, '/guilds/1/channels');
      expect(captured.body, {
        'name': 'general',
        'type': ChannelType.guildText.value,
      });
    },
  );

  test(
    'GuildRestManager.getAuditLogs decodes the entry list, ignoring users/webhooks',
    () async {
      final transport = MockHttpTransport();
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 200,
          headers: {},
          body:
              '{"audit_log_entries": [{"id": "1", "action_type": 10, "user_id": "2", '
              '"reason": "spamming"}], "users": [], "webhooks": []}',
        ),
      );
      final manager = GuildRestManager(
        RestClient(token: 't', transport: transport),
      );

      final entries = await manager.getAuditLogs(
        Snowflake.parse('1'),
        limit: 5,
      );

      expect(entries, hasLength(1));
      expect(entries.single.actionType, 10);
      expect(entries.single.reason, 'spamming');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.path, '/guilds/1/audit-logs?limit=5');
    },
  );
}
