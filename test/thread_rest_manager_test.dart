import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _threadJson =
    '{"id": "50", "type": 11, "guild_id": "1", "parent_id": "10", '
    '"owner_id": "3", "name": "t", "last_message_id": null, '
    '"rate_limit_per_user": 0, "flags": 0, "thread_metadata": '
    '{"archived": false, "auto_archive_duration": 4320, '
    '"archive_timestamp": "2026-10-10T14:08:03.771Z", "locked": false, '
    '"create_timestamp": "2026-10-10T14:08:03.771Z"}, "message_count": 0, '
    '"total_message_sent": 0, "member_count": 1}';

const _memberJson =
    '{"id": "50", "user_id": "3", '
    '"join_timestamp": "2026-10-10T14:08:03.771Z", "flags": 0}';

const _forumJson =
    '{"id": "20", "type": 15, "guild_id": "1", "name": "f", "position": 0, '
    '"parent_id": null, "last_message_id": null, "topic": null, '
    '"nsfw": false, "rate_limit_per_user": 0, "flags": 0, '
    '"available_tags": [{"id": "7", "name": "Solved", "moderated": false, '
    '"emoji_id": null, "emoji_name": null}], '
    '"default_thread_rate_limit_per_user": 0}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  late MockHttpTransport transport;
  late ThreadRestManager threads;
  late ChannelRestManager channels;

  setUp(() {
    transport = MockHttpTransport();
    final client = RestClient(token: 't', transport: transport);
    threads = ThreadRestManager(client);
    channels = ChannelRestManager(client);
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

  group('starting', () {
    test('startFromMessage posts under the message', () async {
      respond(_threadJson, statusCode: 201);

      final thread = await threads.startFromMessage(
        const Snowflake(10),
        const Snowflake(50),
        name: 't',
        autoArchiveDuration: ThreadAutoArchiveDuration.oneDay,
        auditLogReason: 'why',
      );

      expect(thread.id, const Snowflake(50));
      final request = captured();
      expect(request.method, 'POST');
      expect(request.path, '/v1/channels/10/messages/50/threads');
      expect(request.body, {'name': 't', 'auto_archive_duration': 1440});
      expect(request.headers['X-Audit-Log-Reason'], 'why');
    });

    test('start always sends type, defaulting to a public thread', () async {
      respond(_threadJson, statusCode: 201);

      await threads.start(const Snowflake(10), name: 't');

      final request = captured();
      expect(request.path, '/v1/channels/10/threads');
      expect(request.body, {'name': 't', 'type': 11});
    });

    test('start sends the private thread options', () async {
      respond(_threadJson, statusCode: 201);

      await threads.start(
        const Snowflake(10),
        name: 't',
        type: ChannelType.privateThread,
        invitable: false,
        rateLimitPerUser: 7,
      );

      expect(captured().body, {
        'name': 't',
        'type': 12,
        'rate_limit_per_user': 7,
        'invitable': false,
      });
    });

    test(
      'createPost nests the first message and decodes both halves',
      () async {
        respond(
          '${_threadJson.substring(0, _threadJson.length - 1)}, '
          '"applied_tags": ["7"], "message": {"id": "50", "channel_id": "50", '
          '"author": {"id": "3", "username": "bot", "discriminator": "0", '
          '"global_name": null, "avatar": null, "avatar_color": null, '
          '"bot": true, "system": false}, "type": 0, "flags": 0, '
          '"content": "first", "timestamp": "2026-10-10T14:08:15.651Z", '
          '"edited_timestamp": null, "pinned": false, '
          '"mention_everyone": false, "tts": false, "mentions": [], '
          '"mention_roles": []}}',
          statusCode: 201,
        );

        final post = await threads.createPost(
          const Snowflake(20),
          name: 'title',
          message: MessageBuilder(content: 'first'),
          appliedTagIds: const [Snowflake(7)],
        );

        expect(post.thread.appliedTagIds, const [Snowflake(7)]);
        expect(post.message.content, 'first');
        final request = captured();
        expect(request.path, '/v1/channels/20/threads');
        expect(request.body, {
          'name': 'title',
          'message': {'content': 'first'},
          'applied_tags': ['7'],
        });
      },
    );
  });

  group('modifying', () {
    test('update patches the channel route without a type', () async {
      respond(_threadJson);

      await threads.update(
        const Snowflake(50),
        ThreadUpdateBuilder().name('n').archived().locked(false),
      );

      final request = captured();
      expect(request.method, 'PATCH');
      expect(request.path, '/v1/channels/50');
      expect(request.body, {'name': 'n', 'archived': true, 'locked': false});
    });

    test('builder maps pinning onto the flags bitfield', () {
      expect(ThreadUpdateBuilder().pinned().toJson(), {'flags': 2});
      expect(ThreadUpdateBuilder().pinned(false).toJson(), {'flags': 0});
    });

    test('builder sends an empty tag list rather than omitting it', () {
      expect(ThreadUpdateBuilder().appliedTags(const []).toJson(), {
        'applied_tags': <String>[],
      });
      expect(
        ThreadUpdateBuilder()
            .appliedTags(const [Snowflake(7)])
            .autoArchiveDuration(ThreadAutoArchiveDuration.oneWeek)
            .rateLimitPerUser(0)
            .invitable()
            .toJson(),
        {
          'invitable': true,
          'auto_archive_duration': 10080,
          'rate_limit_per_user': 0,
          'applied_tags': ['7'],
        },
      );
    });

    test('delete uses the channel route', () async {
      respond('', statusCode: 204);

      await threads.delete(const Snowflake(50), auditLogReason: 'why');

      final request = captured();
      expect(request.method, 'DELETE');
      expect(request.path, '/v1/channels/50');
      expect(request.headers['X-Audit-Log-Reason'], 'why');
    });
  });

  group('listing', () {
    test('listActive is guild-scoped and unpaged', () async {
      respond('{"threads": [$_threadJson], "members": [$_memberJson]}');

      final list = await threads.listActive(const Snowflake(1));

      expect(list.threads.single.id, const Snowflake(50));
      expect(list.memberFor(const Snowflake(50)), isNotNull);
      expect(list.hasMore, isFalse);
      expect(captured().path, '/v1/guilds/1/threads/active');
    });

    test('public archive pages by an encoded timestamp', () async {
      respond('{"threads": [], "members": [], "has_more": true}');

      final list = await threads.listPublicArchived(
        const Snowflake(10),
        before: DateTime.utc(2026, 10, 10, 14, 8, 30, 700),
        limit: 2,
      );

      expect(list.hasMore, isTrue);
      expect(
        captured().path,
        '/v1/channels/10/threads/archived/public'
        '?limit=2&before=2026-10-10T14%3A08%3A30.700Z',
      );
    });

    test('private archive uses its own route', () async {
      respond('{"threads": [], "members": [], "has_more": false}');

      await threads.listPrivateArchived(const Snowflake(10));

      expect(
        captured().path,
        '/v1/channels/10/threads/archived/private?limit=50',
      );
    });

    test('joined private archive pages by thread id', () async {
      respond('{"threads": [], "members": [], "has_more": false}');

      await threads.listJoinedPrivateArchived(
        const Snowflake(10),
        before: const Snowflake(50),
      );

      expect(
        captured().path,
        '/v1/channels/10/users/@me/threads/archived/private'
        '?limit=50&before=50',
      );
    });
  });

  group('membership', () {
    test('join and leave address @me', () async {
      respond('', statusCode: 204);

      await threads.join(const Snowflake(50));
      await threads.leave(const Snowflake(50));

      final requests = verify(
        () => transport.send(captureAny()),
      ).captured.cast<HttpTransportRequest>();
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'PUT /v1/channels/50/thread-members/@me',
        'DELETE /v1/channels/50/thread-members/@me',
      ]);
    });

    test('addMember and removeMember address the user', () async {
      respond('', statusCode: 204);

      await threads.addMember(const Snowflake(50), const Snowflake(3));
      await threads.removeMember(const Snowflake(50), const Snowflake(3));

      final requests = verify(
        () => transport.send(captureAny()),
      ).captured.cast<HttpTransportRequest>();
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'PUT /v1/channels/50/thread-members/3',
        'DELETE /v1/channels/50/thread-members/3',
      ]);
    });

    test('getMember asks for the guild member only on request', () async {
      respond(_memberJson);

      final member = await threads.getMember(
        const Snowflake(50),
        const Snowflake(3),
      );

      expect(member.userId, const Snowflake(3));
      expect(captured().path, '/v1/channels/50/thread-members/3');
    });

    test('getMember surfaces UNKNOWN_THREAD_MEMBER', () async {
      respond(
        '{"code": "UNKNOWN_THREAD_MEMBER", '
        '"message": "Thread member wasn\'t found."}',
        statusCode: 404,
      );

      expect(
        () => threads.getMember(const Snowflake(50), const Snowflake(3)),
        throwsA(
          isA<FluxerApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'UNKNOWN_THREAD_MEMBER',
          ),
        ),
      );
    });

    test('listMembers decodes a bare array and builds its query', () async {
      respond('[$_memberJson]');

      final members = await threads.listMembers(
        const Snowflake(50),
        withMember: true,
        after: const Snowflake(2),
        limit: 10,
      );

      expect(members.single.threadId, const Snowflake(50));
      expect(
        captured().path,
        '/v1/channels/50/thread-members?limit=10&with_member=true&after=2',
      );
    });
  });

  group('forum tags', () {
    test('createTag posts the tag and returns the forum', () async {
      respond(_forumJson);

      final forum = await channels.createTag(
        const Snowflake(20),
        name: 'Solved',
        emojiName: '✅',
      );

      expect(forum.availableTags.single.name, 'Solved');
      final request = captured();
      expect(request.method, 'POST');
      expect(request.path, '/v1/channels/20/tags');
      expect(request.body, {
        'name': 'Solved',
        'moderated': false,
        'emoji_name': '✅',
      });
    });

    test('updateTag replaces with PUT', () async {
      respond(_forumJson);

      await channels.updateTag(
        const Snowflake(20),
        const Snowflake(7),
        name: 'Done',
        moderated: true,
        emojiId: const Snowflake(9),
      );

      final request = captured();
      expect(request.method, 'PUT');
      expect(request.path, '/v1/channels/20/tags/7');
      expect(request.body, {
        'name': 'Done',
        'moderated': true,
        'emoji_id': '9',
      });
    });

    test('deleteTag returns the forum too', () async {
      respond(_forumJson);

      final forum = await channels.deleteTag(
        const Snowflake(20),
        const Snowflake(7),
      );

      expect(forum, isA<GuildForumChannel>());
      final request = captured();
      expect(request.method, 'DELETE');
      expect(request.path, '/v1/channels/20/tags/7');
    });
  });

  test('ChannelCreateBuilder builds a forum channel body', () {
    expect(
      ChannelCreateBuilder(
        name: 'help',
        type: ChannelType.guildForum,
      ).topic('one question per post').toJson(),
      {'name': 'help', 'type': 15, 'topic': 'one question per post'},
    );
  });
}
