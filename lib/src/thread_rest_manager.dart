import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'message_builder.dart';
import 'rest_client.dart';
import 'thread_update_builder.dart';

/// Thread REST calls: starting, modifying and listing threads and forum
/// posts, and managing thread membership.
///
/// A thread is a channel, so everything addressed by channel id also
/// works on one: `MessageRestManager` sends and lists messages in a
/// thread given the thread's id, and `ChannelRestManager.get` returns it
/// as a [ThreadChannel].
final class ThreadRestManager {
  const ThreadRestManager(this._client);

  final RestClient _client;

  /// Starts a thread from [messageId] in the text or announcement
  /// channel [channelId]. The thread takes the message's id.
  ///
  /// The message must be an ordinary message or a reply, and can start
  /// one thread only. Requires `createPublicThreads` and
  /// `readMessageHistory`.
  Future<ThreadChannel> startFromMessage(
    Snowflake channelId,
    Snowflake messageId, {
    required String name,
    ThreadAutoArchiveDuration? autoArchiveDuration,
    int? rateLimitPerUser,
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/messages/$messageId/threads',
      bucketKey: 'POST /channels/:id/threads',
      body: {
        'name': name,
        'auto_archive_duration': ?autoArchiveDuration?.minutes,
        'rate_limit_per_user': ?rateLimitPerUser,
      },
      auditLogReason: auditLogReason,
    );
    return ThreadChannel.fromJson(json! as Map<String, dynamic>);
  }

  /// Starts a thread with no source message in the text or announcement
  /// channel [channelId].
  ///
  /// [type] is [ChannelType.publicThread] or
  /// [ChannelType.privateThread]; in an announcement channel a public
  /// thread becomes an announcement thread and a private one is
  /// rejected. [invitable] applies to a private thread only. Requires
  /// `createPublicThreads` or `createPrivateThreads` to match.
  ///
  /// For a forum or media channel use [createPost] instead.
  Future<ThreadChannel> start(
    Snowflake channelId, {
    required String name,
    ChannelType type = ChannelType.publicThread,
    ThreadAutoArchiveDuration? autoArchiveDuration,
    int? rateLimitPerUser,
    bool? invitable,
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/threads',
      bucketKey: 'POST /channels/:id/threads',
      body: {
        'name': name,
        'type': type.value,
        'auto_archive_duration': ?autoArchiveDuration?.minutes,
        'rate_limit_per_user': ?rateLimitPerUser,
        'invitable': ?invitable,
      },
      auditLogReason: auditLogReason,
    );
    return ThreadChannel.fromJson(json! as Map<String, dynamic>);
  }

  /// Creates a post in the forum or media channel [channelId].
  ///
  /// [message] becomes the post's first message and shares its id. A
  /// reply reference, nonce or TTS setting on it is not accepted here.
  /// [appliedTagIds] takes up to five of the channel's tags, and at
  /// least one when the channel requires a tag. Requires `sendMessages`
  /// in the channel.
  Future<ForumPost> createPost(
    Snowflake channelId, {
    required String name,
    required MessageBuilder message,
    List<Snowflake> appliedTagIds = const [],
    ThreadAutoArchiveDuration? autoArchiveDuration,
    int? rateLimitPerUser,
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/threads',
      bucketKey: 'POST /channels/:id/threads',
      body: {
        'name': name,
        'message': message.toJson(),
        if (appliedTagIds.isNotEmpty)
          'applied_tags': appliedTagIds
              .map((t) => t.toJson())
              .toList(growable: false),
        'auto_archive_duration': ?autoArchiveDuration?.minutes,
        'rate_limit_per_user': ?rateLimitPerUser,
      },
      auditLogReason: auditLogReason,
    );
    return ForumPost.fromJson(json! as Map<String, dynamic>);
  }

  /// Renames, archives, locks or otherwise modifies a thread.
  ///
  /// Renaming and archiving need the thread owner or a thread moderator;
  /// locking, slowmode and pinning need a thread moderator.
  Future<ThreadChannel> update(
    Snowflake threadId,
    ThreadUpdateBuilder update, {
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/channels/$threadId',
      bucketKey: 'PATCH /channels/:id',
      body: update.toJson(),
      auditLogReason: auditLogReason,
    );
    return ThreadChannel.fromJson(json! as Map<String, dynamic>);
  }

  /// Deletes a thread with its messages and memberships. Requires a
  /// thread moderator.
  Future<void> delete(Snowflake threadId, {String? auditLogReason}) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/channels/$threadId',
        bucketKey: 'DELETE /channels/:id',
        auditLogReason: auditLogReason,
      );

  /// Lists every active thread in [guildId] the bot can view, newest
  /// first. Not paged. Bot tokens only.
  Future<ThreadList> listActive(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/threads/active',
      bucketKey: 'GET /guilds/:id/threads/active',
    );
    return ThreadList.fromJson(json! as Map<String, dynamic>);
  }

  /// Lists archived public threads of [channelId], most recently
  /// archived first. Requires `readMessageHistory`.
  ///
  /// [limit] is 2-100. Page by passing the archive timestamp of the last
  /// thread returned as [before].
  Future<ThreadList> listPublicArchived(
    Snowflake channelId, {
    DateTime? before,
    int limit = 50,
  }) => _listArchived(
    '/channels/$channelId/threads/archived/public',
    before: before?.toUtc().toIso8601String(),
    limit: limit,
  );

  /// Lists archived private threads of the text channel [channelId],
  /// most recently archived first. Requires `readMessageHistory` and a
  /// thread moderator.
  ///
  /// [limit] is 2-100. Page by passing the archive timestamp of the last
  /// thread returned as [before].
  Future<ThreadList> listPrivateArchived(
    Snowflake channelId, {
    DateTime? before,
    int limit = 50,
  }) => _listArchived(
    '/channels/$channelId/threads/archived/private',
    before: before?.toUtc().toIso8601String(),
    limit: limit,
  );

  /// Lists archived private threads of [channelId] that the caller
  /// joined, newest first. Requires `readMessageHistory`.
  ///
  /// Unlike the other archive listings this pages by thread id: pass the
  /// id of the last thread returned as [before].
  Future<ThreadList> listJoinedPrivateArchived(
    Snowflake channelId, {
    Snowflake? before,
    int limit = 50,
  }) => _listArchived(
    '/channels/$channelId/users/@me/threads/archived/private',
    before: before?.toJson(),
    limit: limit,
  );

  Future<ThreadList> _listArchived(
    String path, {
    required String? before,
    required int limit,
  }) async {
    final query = [
      'limit=$limit',
      if (before != null) 'before=${Uri.encodeQueryComponent(before)}',
    ].join('&');
    final json = await _client.requestJson(
      method: 'GET',
      path: '$path?$query',
      bucketKey: 'GET /channels/:id/threads/archived',
    );
    return ThreadList.fromJson(json! as Map<String, dynamic>);
  }

  /// Adds the caller to a thread. A no-op if it already belongs.
  ///
  /// Fails on an archived thread, and on a locked one unless the caller
  /// is a thread moderator.
  Future<void> join(Snowflake threadId) => _client.requestJson(
    method: 'PUT',
    path: '/channels/$threadId/thread-members/@me',
    bucketKey: 'PUT /channels/:id/thread-members/:id',
  );

  /// Removes the caller from a thread.
  Future<void> leave(Snowflake threadId) => _client.requestJson(
    method: 'DELETE',
    path: '/channels/$threadId/thread-members/@me',
    bucketKey: 'DELETE /channels/:id/thread-members/:id',
  );

  /// Adds the guild member [userId] to a thread, posting a system
  /// message in it that mentions them. Requires `sendMessagesInThreads`.
  Future<void> addMember(Snowflake threadId, Snowflake userId) =>
      _client.requestJson(
        method: 'PUT',
        path: '/channels/$threadId/thread-members/$userId',
        bucketKey: 'PUT /channels/:id/thread-members/:id',
      );

  /// Removes [userId] from a thread. Requires a thread moderator, or
  /// ownership of a private thread.
  Future<void> removeMember(Snowflake threadId, Snowflake userId) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/channels/$threadId/thread-members/$userId',
        bucketKey: 'DELETE /channels/:id/thread-members/:id',
      );

  /// Fetches [userId]'s membership in a thread. Bot tokens only.
  ///
  /// Throws a `FluxerApiException` with `UNKNOWN_THREAD_MEMBER` when the
  /// user has not joined. [withMember] also returns their guild member.
  Future<ThreadMember> getMember(
    Snowflake threadId,
    Snowflake userId, {
    bool withMember = false,
  }) async {
    final json = await _client.requestJson(
      method: 'GET',
      path:
          '/channels/$threadId/thread-members/$userId'
          '${withMember ? '?with_member=true' : ''}',
      bucketKey: 'GET /channels/:id/thread-members/:id',
    );
    return ThreadMember.fromJson(json! as Map<String, dynamic>);
  }

  /// Lists a thread's members in ascending user id order. Bot tokens
  /// only.
  ///
  /// [limit] is 1-100. Page by passing the last user id returned as
  /// [after]. [withMember] also returns each user's guild member.
  Future<List<ThreadMember>> listMembers(
    Snowflake threadId, {
    bool withMember = false,
    Snowflake? after,
    int limit = 100,
  }) async {
    final query = [
      'limit=$limit',
      if (withMember) 'with_member=true',
      if (after != null) 'after=${after.toJson()}',
    ].join('&');
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$threadId/thread-members?$query',
      bucketKey: 'GET /channels/:id/thread-members',
    );
    return (json as List<dynamic>)
        .map((m) => ThreadMember.fromJson(m as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Searches the threads of [channelId], usually a forum by post title.
  /// When the index is not ready the result carries
  /// [ThreadSearchResults.retryAfter] instead of threads.
  Future<ThreadSearchResults> search(
    Snowflake channelId, {
    String? name,
    List<Snowflake> tagIds = const [],
    ForumTagSetting? tagSetting,
    bool? archived,
    String? sortBy,
    bool? ascending,
    int limit = 25,
    int offset = 0,
  }) async {
    final query = [
      if (name != null) 'name=${Uri.encodeQueryComponent(name)}',
      for (final tag in tagIds) 'tag=$tag',
      if (tagSetting != null) 'tag_setting=${tagSetting.value}',
      if (archived != null) 'archived=$archived',
      if (sortBy != null) 'sort_by=$sortBy',
      if (ascending != null) 'sort_order=${ascending ? 'asc' : 'desc'}',
      'limit=$limit',
      'offset=$offset',
    ].join('&');
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/threads/search?$query',
      bucketKey: 'GET /channels/:id/threads/search',
    );
    return ThreadSearchResults.fromJson(json as Map<String, dynamic>);
  }

  /// The owner and first message of up to 100 posts in a forum or media
  /// channel, keyed by post id. A post that is not in [channelId] is
  /// missing from the result.
  Future<Map<Snowflake, ForumPostData>> postData(
    Snowflake channelId,
    List<Snowflake> threadIds,
  ) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/post-data',
      bucketKey: 'POST /channels/:id/post-data',
      body: {
        'thread_ids': [for (final id in threadIds) id.toJson()],
      },
    );
    final threads =
        (json as Map<String, dynamic>)['threads'] as Map<String, dynamic>? ??
        const {};
    return {
      for (final MapEntry(:key, :value) in threads.entries)
        Snowflake.parse(key): ForumPostData.fromJson(
          value as Map<String, dynamic>,
        ),
    };
  }
}
