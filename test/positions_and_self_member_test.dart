import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _role =
    '{"id":"5","name":"r","color":3368703,"position":2,"hoist_position":null,'
    '"permissions":"0","hoist":true,"mentionable":true}';

const _member =
    '{"user":{"id":"9","username":"bot","discriminator":"0001","bot":true},'
    '"nick":"rec nick","avatar":null,"banner":null,"accent_color":null,'
    '"roles":[],"joined_at":"2026-08-12T06:10:10.527Z","mute":false,'
    '"deaf":false,"communication_disabled_until":null}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  late MockHttpTransport transport;
  late RestClient client;
  final guild = Snowflake.parse('1');

  void answer(int status, String body) =>
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: status,
          headers: const {},
          body: body,
        ),
      );

  HttpTransportRequest sent() =>
      verify(() => transport.send(captureAny())).captured.single
          as HttpTransportRequest;

  setUp(() {
    transport = MockHttpTransport();
    client = RestClient(token: 't', transport: transport);
  });

  group('GuildRestManager', () {
    test('listChannels decodes every channel type it is given', () async {
      answer(
        200,
        '[{"id":"2","type":4,"guild_id":"1","name":"Text Channels",'
        '"position":0,"permission_overwrites":[],"nsfw":false},'
        '{"id":"3","type":0,"guild_id":"1","name":"general","position":0,'
        '"parent_id":"2","permission_overwrites":[],"nsfw":false,'
        '"topic":null,"last_message_id":null,"rate_limit_per_user":0}]',
      );

      final channels = await GuildRestManager(client).listChannels(guild);

      expect(channels.first, isA<GuildCategoryChannel>());
      expect(channels.last, isA<GuildTextChannel>());
      expect(sent().path, '/v1/guilds/1/channels');
    });

    test('updateChannelPositions sends a bare array', () async {
      answer(204, '');

      await GuildRestManager(client).updateChannelPositions(guild, [
        ChannelPositionUpdate(Snowflake.parse('3'), position: 0),
        ChannelPositionUpdate(
          Snowflake.parse('4'),
          parentId: Snowflake.parse('2'),
          lockPermissions: true,
        ),
        ChannelPositionUpdate(Snowflake.parse('5'), moveToTopLevel: true),
      ]);

      final request = sent();
      expect(request.method, 'PATCH');
      expect(request.body, [
        {'id': '3', 'position': 0},
        {'id': '4', 'parent_id': '2', 'lock_permissions': true},
        {'id': '5', 'parent_id': null},
      ]);
    });
  });

  group('GuildRoleRestManager', () {
    test('update sends only the fields set', () async {
      answer(200, _role);

      final role = await GuildRoleRestManager(client).update(
        guild,
        Snowflake.parse('5'),
        GuildRoleUpdateBuilder()
            .name('r')
            .color(0x3366ff)
            .hoist()
            .mentionable(),
      );

      expect(role.hoist, isTrue);
      final request = sent();
      expect(request.method, 'PATCH');
      expect(request.path, '/v1/guilds/1/roles/5');
      expect(request.body, {
        'name': 'r',
        'color': 0x3366ff,
        'hoist': true,
        'mentionable': true,
      });
    });

    test('updatePositions maps ids to positions', () async {
      answer(204, '');

      await GuildRoleRestManager(client).updatePositions(guild, {
        Snowflake.parse('5'): 2,
        Snowflake.parse('6'): 1,
      });

      expect(sent().body, [
        {'id': '5', 'position': 2},
        {'id': '6', 'position': 1},
      ]);
    });

    test('updateHoistPositions and resetHoistPositions', () async {
      answer(204, '');
      final roles = GuildRoleRestManager(client);

      await roles.updateHoistPositions(guild, {Snowflake.parse('5'): 1});
      final set = sent();
      expect(set.method, 'PATCH');
      expect(set.path, '/v1/guilds/1/roles/hoist-positions');
      expect(set.body, [
        {'id': '5', 'hoist_position': 1},
      ]);

      await roles.resetHoistPositions(guild);
      final reset = sent();
      expect(reset.method, 'DELETE');
      expect(reset.path, '/v1/guilds/1/roles/hoist-positions');
    });
  });

  group('GuildMemberRestManager', () {
    test('getCurrent reads the @me member', () async {
      answer(200, _member);

      final me = await GuildMemberRestManager(client).getCurrent(guild);

      expect(me.nick, 'rec nick');
      expect(sent().path, '/v1/guilds/1/members/@me');
    });

    test('updateCurrent sends an explicit null to clear a field', () async {
      answer(200, _member);

      await GuildMemberRestManager(
        client,
      ).updateCurrent(guild, CurrentMemberUpdateBuilder().nick(null).bio('hi'));

      final request = sent();
      expect(request.method, 'PATCH');
      expect(request.body, {'nick': null, 'bio': 'hi'});
    });
  });
}
