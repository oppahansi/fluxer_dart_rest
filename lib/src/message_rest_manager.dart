import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'message_builder.dart';
import 'message_search_builder.dart';
import 'rest_client.dart';

/// Message-resource REST calls, covering the `/channels/{id}/messages`,
/// reaction, pin and typing routes.
final class MessageRestManager {
  const MessageRestManager(this._client);

  final RestClient _client;

  /// Lists up to [limit] (1-100, default 50) recent messages in
  /// [channelId], newest first.
  ///
  /// [before] and [after] page through history relative to a message id;
  /// [around] centres the window on one. They are mutually exclusive.
  Future<List<Message>> list(
    Snowflake channelId, {
    int limit = 50,
    Snowflake? before,
    Snowflake? after,
    Snowflake? around,
  }) async {
    final query = {
      'limit': '$limit',
      if (before != null) 'before': before.toJson(),
      if (after != null) 'after': after.toJson(),
      if (around != null) 'around': around.toJson(),
    };
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/messages${_query(query)}',
      bucketKey: 'GET /channels/:id/messages',
    );
    return (json as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Fetches a single message.
  Future<Message> fetch(Snowflake channelId, Snowflake messageId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/messages/$messageId',
      bucketKey: 'GET /channels/:id/messages/:id',
    );
    return Message.fromJson(json!);
  }

  Future<Message> send(Snowflake channelId, MessageBuilder message) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/messages',
      bucketKey: 'POST /channels/:id/messages',
      body: message.toJson(),
    );
    return Message.fromJson(json!);
  }

  Future<Message> edit(
    Snowflake channelId,
    Snowflake messageId,
    MessageBuilder message,
  ) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/channels/$channelId/messages/$messageId',
      bucketKey: 'PATCH /channels/:id/messages/:id',
      body: message.toJson(),
    );
    return Message.fromJson(json!);
  }

  Future<void> delete(
    Snowflake channelId,
    Snowflake messageId, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'DELETE',
    path: '/channels/$channelId/messages/$messageId',
    bucketKey: 'DELETE /channels/:id/messages/:id',
    auditLogReason: auditLogReason,
  );

  /// Deletes 1-100 messages in one call. Guild channels only.
  Future<void> bulkDelete(
    Snowflake channelId,
    List<Snowflake> messageIds, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'POST',
    path: '/channels/$channelId/messages/bulk-delete',
    bucketKey: 'POST /channels/:id/messages/bulk-delete',
    body: {'message_ids': messageIds.map((id) => id.toJson()).toList()},
    auditLogReason: auditLogReason,
  );

  /// Deletes the caller's own recent messages in [channelId], without
  /// needing `manageMessages`.
  Future<void> bulkDeleteMine(Snowflake channelId) => _client.requestJson(
    method: 'POST',
    path: '/channels/$channelId/messages/bulk-delete-mine',
    bucketKey: 'POST /channels/:id/messages/bulk-delete-mine',
  );

  /// Shows the typing indicator in [channelId] for roughly ten seconds.
  ///
  /// There is no route to stop it early; sending a message clears it.
  Future<void> triggerTyping(Snowflake channelId) => _client.requestJson(
    method: 'POST',
    path: '/channels/$channelId/typing',
    bucketKey: 'POST /channels/:id/typing',
  );

  /// Adds a reaction to a message, as the bot.
  ///
  /// [emoji] is a standard emoji's Unicode character, or a custom guild
  /// emoji written `name:id`. The route takes it as an opaque path
  /// segment either way.
  Future<void> addReaction(
    Snowflake channelId,
    Snowflake messageId,
    String emoji,
  ) => _client.requestJson(
    method: 'PUT',
    path:
        '/channels/$channelId/messages/$messageId/reactions/'
        '${_emoji(emoji)}/@me',
    bucketKey: 'PUT /channels/:id/messages/:id/reactions/:emoji/@me',
  );

  /// Removes [userId]'s reaction. Requires `manageMessages` unless
  /// [userId] is the bot itself.
  Future<void> removeReaction(
    Snowflake channelId,
    Snowflake messageId,
    String emoji,
    Snowflake userId,
  ) => _client.requestJson(
    method: 'DELETE',
    path:
        '/channels/$channelId/messages/$messageId/reactions/'
        '${_emoji(emoji)}/$userId',
    bucketKey: 'DELETE /channels/:id/messages/:id/reactions/:emoji/:user',
  );

  /// Removes the bot's own reaction, needing no extra permission.
  Future<void> removeOwnReaction(
    Snowflake channelId,
    Snowflake messageId,
    String emoji,
  ) => _client.requestJson(
    method: 'DELETE',
    path:
        '/channels/$channelId/messages/$messageId/reactions/'
        '${_emoji(emoji)}/@me',
    bucketKey: 'DELETE /channels/:id/messages/:id/reactions/:emoji/@me',
  );

  /// Clears every reaction from a message. Requires `manageMessages`.
  Future<void> removeAllReactions(Snowflake channelId, Snowflake messageId) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/channels/$channelId/messages/$messageId/reactions',
        bucketKey: 'DELETE /channels/:id/messages/:id/reactions',
      );

  /// Clears every reaction using one emoji. Requires `manageMessages`.
  Future<void> removeEmojiReactions(
    Snowflake channelId,
    Snowflake messageId,
    String emoji,
  ) => _client.requestJson(
    method: 'DELETE',
    path: '/channels/$channelId/messages/$messageId/reactions/${_emoji(emoji)}',
    bucketKey: 'DELETE /channels/:id/messages/:id/reactions/:emoji',
  );

  /// Lists users who reacted with [emoji], one page at a time.
  ///
  /// [after] takes the previous page's [Page.nextAfter].
  Future<Page<User>> listReactionUsers(
    Snowflake channelId,
    Snowflake messageId,
    String emoji, {
    int limit = 100,
    Snowflake? after,
  }) async {
    final query = {
      'limit': '$limit',
      if (after != null) 'after': after.toJson(),
    };
    final json = await _client.requestJson(
      method: 'GET',
      path:
          '/channels/$channelId/messages/$messageId/reactions/'
          '${_emoji(emoji)}/users${_query(query)}',
      bucketKey: 'GET /channels/:id/messages/:id/reactions/:emoji/users',
    );
    return Page.fromJson(json! as Map<String, dynamic>, User.fromJson);
  }

  /// Lists a channel's pinned messages, newest pin first.
  ///
  /// The route answers with a page envelope rather than a bare array, and
  /// each entry wraps its message alongside the time it was pinned.
  Future<Page<PinnedMessage>> pins(
    Snowflake channelId, {
    Snowflake? before,
    int? limit,
  }) async {
    final query = {
      if (limit != null) 'limit': '$limit',
      if (before != null) 'before': before.toJson(),
    };
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/messages/pins${_query(query)}',
      bucketKey: 'GET /channels/:id/messages/pins',
    );
    return Page.fromJson(json! as Map<String, dynamic>, PinnedMessage.fromJson);
  }

  /// Pins a message. Requires `pinMessages`.
  Future<void> pin(
    Snowflake channelId,
    Snowflake messageId, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'PUT',
    path: '/channels/$channelId/pins/$messageId',
    bucketKey: 'PUT /channels/:id/pins/:id',
    auditLogReason: auditLogReason,
  );

  /// Unpins a message. Requires `pinMessages`.
  Future<void> unpin(
    Snowflake channelId,
    Snowflake messageId, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'DELETE',
    path: '/channels/$channelId/pins/$messageId',
    bucketKey: 'DELETE /channels/:id/pins/:id',
    auditLogReason: auditLogReason,
  );

  /// Percent-encodes an emoji for use as a path segment. A custom emoji
  /// is written `name:id`, a standard one as its Unicode character.
  static String _emoji(String emoji) => Uri.encodeComponent(emoji);

  static String _query(Map<String, String> params) => params.isEmpty
      ? ''
      : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

  /// Publishes a message in an announcement channel to every channel
  /// following it.
  ///
  /// Only a [MessageType.default_] message that is not a reply, a forward
  /// or itself a copy can be published. Requires `sendMessages`, plus
  /// `manageMessages` to publish someone else's message or a webhook's.
  /// Rate limited to 10 consecutive publishes per channel, then one every
  /// six minutes.
  ///
  /// Returns the source message with [MessageFlag.crossposted] set.
  Future<Message> crosspost(Snowflake channelId, Snowflake messageId) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/messages/$messageId/crosspost',
      bucketKey: 'POST /channels/:id/messages/:id/crosspost',
    );
    return Message.fromJson(json!);
  }

  /// The guild a copy came from, for a message carrying
  /// [MessageFlag.isCrosspost].
  Future<CrosspostSource> crosspostSource(
    Snowflake channelId,
    Snowflake messageId,
  ) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/messages/$messageId/crosspost-source',
      bucketKey: 'GET /channels/:id/messages/:id/crosspost-source',
    );
    return CrosspostSource.fromJson(json! as Map<String, dynamic>);
  }

  /// Searches messages, newest first unless the builder says otherwise.
  ///
  /// Search runs against an index that is filled shortly after a message
  /// is sent, so a message can be missing for a moment after creation;
  /// while the index is being built the result has
  /// [MessageSearchResults.indexing] set.
  Future<MessageSearchResults> search(MessageSearchBuilder search) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/search/messages',
      bucketKey: 'POST /search/messages',
      body: search.toJson(),
    );
    return MessageSearchResults.fromJson(json as Map<String, dynamic>);
  }
}
