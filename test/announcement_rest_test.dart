import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _messageJson =
    '{"id": "1", "channel_id": "2", "author": {"id": "3", "username": "bot", '
    '"discriminator": "0", "global_name": null, "avatar": null, '
    '"avatar_color": null, "bot": true, "system": false}, "type": 0, '
    '"flags": 1, "content": "hi", "timestamp": "2026-10-02T12:00:00.000Z", '
    '"edited_timestamp": null, "pinned": false, "mention_everyone": false, '
    '"tts": false, "mentions": [], "mention_roles": []}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  late MockHttpTransport transport;
  late RestClient client;

  setUp(() {
    transport = MockHttpTransport();
    client = RestClient(token: 't', transport: transport);
  });

  void respond(String body) {
    when(() => transport.send(any())).thenAnswer(
      (_) async =>
          HttpTransportResponse(statusCode: 200, headers: const {}, body: body),
    );
  }

  HttpTransportRequest captured() =>
      verify(() => transport.send(captureAny())).captured.single
          as HttpTransportRequest;

  group('following', () {
    test('follow posts webhook_channel_id and decodes the result', () async {
      respond('{"channel_id": "10", "webhook_id": "11"}');

      final followed = await ChannelRestManager(client).follow(
        const Snowflake(10),
        targetChannelId: const Snowflake(20),
        auditLogReason: 'because',
      );

      expect(followed.channelId, const Snowflake(10));
      expect(followed.webhookId, const Snowflake(11));
      final request = captured();
      expect(request.method, 'POST');
      expect(request.path, '/v1/channels/10/followers');
      expect(request.body, {'webhook_channel_id': '20'});
      expect(request.headers['X-Audit-Log-Reason'], 'because');
    });

    test('followerStats decodes both counts', () async {
      respond('{"channel_count": 3, "guild_count": 2}');

      final stats = await ChannelRestManager(
        client,
      ).followerStats(const Snowflake(10));

      expect(stats.channelCount, 3);
      expect(stats.guildCount, 2);
      expect(captured().path, '/v1/channels/10/follower-stats');
    });
  });

  group('crossposting', () {
    test('crosspost returns the message with the crossposted flag', () async {
      respond(_messageJson);

      final message = await MessageRestManager(
        client,
      ).crosspost(const Snowflake(2), const Snowflake(1));

      expect(message.isCrossposted, isTrue);
      final request = captured();
      expect(request.method, 'POST');
      expect(request.path, '/v1/channels/2/messages/1/crosspost');
    });

    test('crosspostSource decodes the source guild', () async {
      respond(
        '{"guild": {"id": "9", "name": "Somewhere", "icon": null, '
        '"features": ["BANNER"], "approximate_member_count": 42, '
        '"discoverable": true}}',
      );

      final source = await MessageRestManager(
        client,
      ).crosspostSource(const Snowflake(2), const Snowflake(1));

      expect(source.guild.id, const Snowflake(9));
      expect(source.guild.name, 'Somewhere');
      expect(source.guild.approximateMemberCount, 42);
      expect(source.guild.discoverable, isTrue);
      expect(source.guild.features, ['BANNER']);
      expect(captured().path, '/v1/channels/2/messages/1/crosspost-source');
    });
  });

  group('attachment url refresh', () {
    test('posts the url list and preserves request order', () async {
      respond(
        '{"refreshed_urls": ['
        '{"original": "https://a.invalid/1", '
        '"refreshed": "https://a.invalid/1?sig=new"},'
        '{"original": "https://b.invalid/2", '
        '"refreshed": "https://b.invalid/2"}'
        ']}',
      );

      final refreshed = await AttachmentRestManager(
        client,
      ).refreshUrls(['https://a.invalid/1', 'https://b.invalid/2']);

      expect(refreshed, hasLength(2));
      expect(refreshed.first.wasRefreshed, isTrue);
      expect(refreshed.first.refreshed, 'https://a.invalid/1?sig=new');
      expect(refreshed.last.wasRefreshed, isFalse);
      final request = captured();
      expect(request.path, '/v1/attachments/refresh-urls');
      expect(request.body, {
        'attachment_urls': ['https://a.invalid/1', 'https://b.invalid/2'],
      });
    });
  });

  group('expression source', () {
    test('emoji source decodes a partial guild', () async {
      respond(
        '{"id": "9", "name": "Owner Guild", "icon": "abc", "features": []}',
      );

      final guild = await GuildEmojiRestManager(
        client,
      ).source(const Snowflake(5));

      expect(guild.id, const Snowflake(9));
      expect(guild.name, 'Owner Guild');
      expect(captured().path, '/v1/emojis/5/source');
    });

    test('sticker source hits the sticker route', () async {
      respond('{"id": "9", "name": "Owner Guild", "features": []}');

      await GuildStickerRestManager(client).source(const Snowflake(5));

      expect(captured().path, '/v1/stickers/5/source');
    });
  });
}
