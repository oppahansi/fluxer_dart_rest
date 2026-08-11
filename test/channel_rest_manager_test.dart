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

  test('ChannelRestManager.update PATCHes the built payload', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async => const HttpTransportResponse(
        statusCode: 200,
        headers: {},
        body:
            '{"id": "1", "type": 0, "name": "renamed", "guild_id": "2", "topic": null, '
            '"position": 0, "parent_id": null, "last_message_id": null, "nsfw": false, "rate_limit_per_user": 0}',
      ),
    );
    final manager = ChannelRestManager(
      RestClient(token: 't', transport: transport),
    );

    final channel = await manager.update(
      Snowflake.parse('1'),
      ChannelUpdateBuilder(ChannelType.guildText).name('renamed'),
    );

    expect((channel as GuildTextChannel).name, 'renamed');
    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'PATCH');
    expect(captured.path, '/channels/1');
    expect(captured.body, {
      'type': ChannelType.guildText.value,
      'name': 'renamed',
    });
  });

  test('ChannelRestManager.delete sends a DELETE', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async =>
          const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
    );
    final manager = ChannelRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.delete(Snowflake.parse('1'));

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'DELETE');
    expect(captured.path, '/channels/1');
  });

  test(
    'ChannelRestManager.setPermissionOverwrite PUTs the overwrite payload',
    () async {
      final transport = MockHttpTransport();
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );
      final manager = ChannelRestManager(
        RestClient(token: 't', transport: transport),
      );

      await manager.setPermissionOverwrite(
        Snowflake.parse('1'),
        Snowflake.parse('9'),
        const PermissionOverwrite(
          type: PermissionOverwriteType.role,
          allow: Permissions.none,
          deny: Permissions.none,
        ),
      );

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'PUT');
      expect(captured.path, '/channels/1/permissions/9');
      expect(captured.body, {'type': 0, 'allow': '0', 'deny': '0'});
    },
  );

  test('ChannelRestManager.deletePermissionOverwrite sends a DELETE', () async {
    final transport = MockHttpTransport();
    when(() => transport.send(any())).thenAnswer(
      (_) async =>
          const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
    );
    final manager = ChannelRestManager(
      RestClient(token: 't', transport: transport),
    );

    await manager.deletePermissionOverwrite(
      Snowflake.parse('1'),
      Snowflake.parse('9'),
    );

    final captured =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(captured.method, 'DELETE');
    expect(captured.path, '/channels/1/permissions/9');
  });
}
