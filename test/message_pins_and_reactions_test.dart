import 'dart:convert';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _messageJson =
    '{"id": "1", "channel_id": "2", "author": {"id": "3", "username": "bot", '
    '"discriminator": "0", "global_name": null, "avatar": null, '
    '"avatar_color": null, "bot": true, "system": false}, "type": 0, '
    '"flags": 0, "content": "hi", "timestamp": "2026-08-11T12:00:00.000Z", '
    '"edited_timestamp": null, "pinned": true, "mention_everyone": false, '
    '"tts": false, "mentions": [], "mention_roles": []}';

const _userJson =
    '{"id": "7", "username": "someone", "discriminator": "0001", '
    '"global_name": null, "avatar": null, "avatar_color": null, '
    '"bot": false, "system": false}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  late MockHttpTransport transport;
  late MessageRestManager manager;

  setUp(() {
    transport = MockHttpTransport();
    manager = MessageRestManager(RestClient(token: 't', transport: transport));
  });

  void respond(String body, {int statusCode = 200}) {
    when(() => transport.send(any())).thenAnswer(
      (_) async => HttpTransportResponse(
        statusCode: statusCode,
        headers: const {},
        body: body,
      ),
    );
  }

  HttpTransportRequest captured() =>
      verify(() => transport.send(captureAny())).captured.single
          as HttpTransportRequest;

  group('pins', () {
    test('pins() decodes the page envelope, not a bare array', () async {
      respond(
        '{"items": [{"message": $_messageJson, '
        '"pinned_at": "2026-09-07T20:50:44.426Z"}], "has_more": false}',
      );

      final page = await manager.pins(Snowflake.parse('2'));

      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
      expect(page.items.single.message.content, 'hi');
      expect(
        page.items.single.pinnedAt,
        DateTime.utc(2026, 9, 7, 20, 50, 44, 426),
      );
      expect(captured().path, '/v1/channels/2/messages/pins');
    });

    test('pin() PUTs to the pins route and forwards an audit reason', () async {
      respond('');

      await manager.pin(
        Snowflake.parse('2'),
        Snowflake.parse('1'),
        auditLogReason: 'important',
      );

      final request = captured();
      expect(request.method, 'PUT');
      expect(request.path, '/v1/channels/2/pins/1');
      expect(request.headers['X-Audit-Log-Reason'], 'important');
    });

    test('unpin() DELETEs the same route', () async {
      respond('');

      await manager.unpin(Snowflake.parse('2'), Snowflake.parse('1'));

      final request = captured();
      expect(request.method, 'DELETE');
      expect(request.path, '/v1/channels/2/pins/1');
    });
  });

  group('reactions', () {
    test('removeAllReactions targets the collection route', () async {
      respond('');

      await manager.removeAllReactions(
        Snowflake.parse('2'),
        Snowflake.parse('1'),
      );

      final request = captured();
      expect(request.method, 'DELETE');
      expect(request.path, '/v1/channels/2/messages/1/reactions');
    });

    test('removeEmojiReactions percent-encodes the emoji', () async {
      respond('');

      await manager.removeEmojiReactions(
        Snowflake.parse('2'),
        Snowflake.parse('1'),
        '👍',
      );

      expect(
        captured().path,
        '/v1/channels/2/messages/1/reactions/${Uri.encodeComponent('👍')}',
      );
    });

    test('removeOwnReaction targets @me', () async {
      respond('');

      await manager.removeOwnReaction(
        Snowflake.parse('2'),
        Snowflake.parse('1'),
        '👍',
      );

      expect(captured().path, endsWith('/@me'));
    });

    test('listReactionUsers decodes a cursor page', () async {
      respond('{"items": [$_userJson], "has_more": true, "next_after": "7"}');

      final page = await manager.listReactionUsers(
        Snowflake.parse('2'),
        Snowflake.parse('1'),
        '👍',
        limit: 50,
      );

      expect(page.items.single.username, 'someone');
      expect(page.hasMore, isTrue);
      expect(page.nextAfter, Snowflake.parse('7'));
      expect(captured().path, contains('/users?limit=50'));
    });
  });

  test('triggerTyping posts to the typing route', () async {
    respond('');

    await manager.triggerTyping(Snowflake.parse('2'));

    final request = captured();
    expect(request.method, 'POST');
    expect(request.path, '/v1/channels/2/typing');
  });

  test('fetch decodes a single message', () async {
    respond(_messageJson);

    final message = await manager.fetch(
      Snowflake.parse('2'),
      Snowflake.parse('1'),
    );

    expect(message.id, Snowflake.parse('1'));
    expect(captured().path, '/v1/channels/2/messages/1');
  });

  test('list passes before/after cursors through', () async {
    respond('[]');

    await manager.list(
      Snowflake.parse('2'),
      limit: 5,
      before: Snowflake.parse('9'),
    );

    expect(captured().path, '/v1/channels/2/messages?limit=5&before=9');
  });

  group('MessageBuilder', () {
    test('serialises the full send body', () {
      final json = MessageBuilder(content: 'hi')
          .allowedMentions(AllowedMentions.none)
          .flag(MessageFlag.suppressNotifications)
          .sticker(Snowflake.parse('5'))
          .tts()
          .nonce('abc')
          .toJson();

      expect(json['content'], 'hi');
      expect(json['allowed_mentions'], {'parse': <String>[]});
      expect(json['flags'], MessageFlag.suppressNotifications.bit);
      expect(json['sticker_ids'], ['5']);
      expect(json['tts'], true);
      expect(json['nonce'], 'abc');
    });

    test('omits every optional field when unset', () {
      final json = MessageBuilder(content: 'hi').toJson();

      expect(json.keys, ['content']);
    });

    test('an attachment alone satisfies the content requirement', () {
      final json = MessageBuilder()
          .attachment(
            const UploadedAttachment(
              id: 0,
              filename: 'a.png',
              uploadFilename: 'key',
              fileSize: 3,
              contentType: 'image/png',
            ),
          )
          .toJson();

      expect(
        (json['attachments'] as List<dynamic>).single,
        containsPair('upload_filename', 'key'),
      );
    });

    test('an empty builder is rejected', () {
      expect(MessageBuilder().toJson, throwsStateError);
    });

    test('allowedMentions carries explicit ids', () {
      final json = MessageBuilder(content: 'hi')
          .allowedMentions(
            AllowedMentions(
              parse: const [MentionType.users],
              roles: [Snowflake.parse('4')],
              repliedUser: false,
            ),
          )
          .toJson();

      expect(
        jsonEncode(json['allowed_mentions']),
        jsonEncode({
          'parse': ['users'],
          'roles': ['4'],
          'replied_user': false,
        }),
      );
    });
  });
}
