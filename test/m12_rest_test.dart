import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _message =
    '{"id":"5","channel_id":"2","author":{"id":"9","username":"hook",'
    '"discriminator":"0000","bot":true},"type":0,"flags":0,"content":"hi",'
    '"timestamp":"2026-10-20T18:24:12.246Z","edited_timestamp":null,'
    '"pinned":false,"mention_everyone":false,"tts":false,"mentions":[],'
    '"mention_roles":[],"webhook_id":"7"}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  late MockHttpTransport transport;
  late RestClient client;

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

  test('field errors from a 400 reach the exception', () async {
    answer(
      400,
      '{"code":"INVALID_FORM_BODY","message":"Invalid form body.",'
      '"errors":[{"path":"code","message":"Vanity URL requires VANITY_URL '
      'feature.","code":"VANITY_URL_REQUIRES_FEATURE"}]}',
    );

    await expectLater(
      GuildRestManager(client).updateVanityUrl(const Snowflake(1), 'x'),
      throwsA(
        isA<FluxerApiException>().having(
          (e) => e.fieldErrors.single.code,
          'field code',
          'VANITY_URL_REQUIRES_FEATURE',
        ),
      ),
    );
  });

  test('message search sends the builder body', () async {
    answer(
      200,
      '{"messages":[$_message],"channels":[],"total":1,'
      '"hits_per_page":25,"page":1}',
    );

    final results = await MessageRestManager(client).search(
      MessageSearchBuilder()
          .inGuild(const Snowflake(1))
          .content('needle')
          .authors([const Snowflake(9)])
          .has([MessageContentKind.link])
          .page(2, hitsPerPage: 10),
    );

    expect(results.messages.single.content, 'hi');
    expect(sent().body, {
      'context_guild_id': '1',
      'scope': 'current',
      'content': 'needle',
      'author_id': ['9'],
      'has': ['link'],
      'page': 2,
      'hits_per_page': 10,
    });
  });

  test('thread search repeats tag in the query', () async {
    answer(
      200,
      '{"threads":[],"members":[],"has_more":false,"total_results":0}',
    );

    await ThreadRestManager(client).search(
      const Snowflake(3),
      name: 'a b',
      tagIds: [const Snowflake(4), const Snowflake(5)],
      tagSetting: ForumTagSetting.matchAll,
    );

    expect(
      sent().path,
      '/v1/channels/3/threads/search?name=a+b&tag=4&tag=5'
      '&tag_setting=match_all&limit=25&offset=0',
    );
  });

  test('post data is keyed by thread id', () async {
    answer(200, '{"threads":{"8":{"owner":null,"first_message":$_message}}}');

    final data = await ThreadRestManager(
      client,
    ).postData(const Snowflake(3), [const Snowflake(8)]);

    expect(data[const Snowflake(8)]!.firstMessage!.content, 'hi');
    expect(sent().body, {
      'thread_ids': ['8'],
    });
  });

  test('discovery apply sends only what is given', () async {
    answer(
      200,
      '{"guild_id":"1","status":"pending","description":"d",'
      '"category_type":0,"primary_language":"en-US","custom_tags":[],'
      '"applied_at":"2026-10-20T18:24:18.985Z","reviewed_at":null}',
    );

    final application = await DiscoveryRestManager(
      client,
    ).apply(const Snowflake(1), description: 'd', categoryType: 0);

    expect(application.isPending, isTrue);
    expect(sent().body, {'description': 'd', 'category_type': 0});
  });

  test('profile query and the destructive bulk delete path', () async {
    answer(
      200,
      '{"user":{"id":"9","username":"u","discriminator":"1"},'
      '"user_profile":{"bio":"b","pronouns":null,"banner":null,'
      '"accent_color":null},"timezone_offset":null}',
    );
    final users = UserRestManager(client);

    final profile = await users.profile(
      const Snowflake(9),
      guildId: const Snowflake(1),
      withMutualGuilds: true,
    );
    expect(profile.bio, 'b');
    expect(
      sent().path,
      '/v1/users/9/profile?guild_id=1&with_mutual_guilds=true',
    );

    answer(202, '');
    await users.deleteAllOwnMessagesInGuild(const Snowflake(1));
    expect(sent().path, '/v1/users/@me/guilds/1/messages/bulk-delete-mine');
  });

  test('sticker update always sends the name', () async {
    answer(
      200,
      '{"id":"6","name":"n","description":"","tags":["b"],'
      '"animated":false,"nsfw":false}',
    );

    await GuildStickerRestManager(
      client,
    ).update(const Snowflake(1), const Snowflake(6), name: 'n', tags: ['b']);

    expect(sent().body, {
      'name': 'n',
      'tags': ['b'],
    });
  });

  test('emoji bulk create', () async {
    answer(
      200,
      '{"success":[{"id":"6","name":"a","animated":false,"nsfw":false}],'
      '"failed":[{"name":"b","error":"x"}]}',
    );

    final result = await GuildEmojiRestManager(client).bulkCreate(
      const Snowflake(1),
      [(name: 'a', image: 'data:image/png;base64,AA')],
    );

    expect(result.created.single.name, 'a');
    expect(result.failed.single.error, 'x');
    expect(sent().body, {
      'emojis': [
        {'name': 'a', 'image': 'data:image/png;base64,AA'},
      ],
    });
  });

  group('WebhookExecuteClient', () {
    late WebhookExecuteClient webhooks;

    setUp(() => webhooks = WebhookExecuteClient(transport: transport));

    test('executeAndWait adds wait and thread_id, never auth', () async {
      answer(200, _message);

      final message = await webhooks.executeAndWait(
        const Snowflake(7),
        'tok',
        content: 'hi',
        threadId: const Snowflake(8),
      );

      expect(message.content, 'hi');
      final request = sent();
      expect(request.path, '/v1/webhooks/7/tok?wait=true&thread_id=8');
      expect(request.headers.keys, isNot(contains('Authorization')));
    });

    test('a forum post through a webhook', () async {
      answer(204, '');

      await webhooks.execute(
        const Snowflake(7),
        'tok',
        content: 'c',
        threadName: 'post',
        appliedTagIds: [const Snowflake(4)],
      );

      expect(sent().body, {
        'content': 'c',
        'thread_name': 'post',
        'applied_tags': ['4'],
      });
    });

    test('message and webhook routes by token', () async {
      answer(200, _message);
      await webhooks.editMessage(
        const Snowflake(7),
        'tok',
        const Snowflake(5),
        content: 'e',
      );
      final edit = sent();
      expect(edit.method, 'PATCH');
      expect(edit.path, '/v1/webhooks/7/tok/messages/5');
      expect(edit.body, {'content': 'e'});

      answer(
        200,
        '{"id":"7","guild_id":"1","channel_id":"2","name":"n",'
        '"avatar":null,"type":1,"token":"tok"}',
      );
      final hook = await webhooks.get(const Snowflake(7), 'tok');
      expect(hook.creator, isNull);
      expect(sent().path, '/v1/webhooks/7/tok');

      answer(204, '');
      await webhooks.deleteMessage(
        const Snowflake(7),
        'tok',
        const Snowflake(5),
      );
      expect(sent().method, 'DELETE');
    });
  });
}
