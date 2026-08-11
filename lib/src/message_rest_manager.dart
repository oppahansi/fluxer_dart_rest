import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'message_builder.dart';
import 'rest_client.dart';

/// Message-resource REST calls, mirroring Fluxer's own
/// `/channels/{id}/messages` OpenAPI grouping.
final class MessageRestManager {
  const MessageRestManager(this._client);

  final RestClient _client;

  /// Lists up to [limit] (1-100, default 50) recent messages in
  /// [channelId], newest first.
  Future<List<Message>> list(Snowflake channelId, {int limit = 50}) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/messages?limit=$limit',
      bucketKey: 'GET /channels/:id/messages',
    );
    return (json as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList(growable: false);
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

  Future<void> delete(Snowflake channelId, Snowflake messageId) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/channels/$channelId/messages/$messageId',
        bucketKey: 'DELETE /channels/:id/messages/:id',
      );

  /// Deletes up to 100 messages in one call.
  Future<void> bulkDelete(Snowflake channelId, List<Snowflake> messageIds) =>
      _client.requestJson(
        method: 'POST',
        path: '/channels/$channelId/messages/bulk-delete',
        bucketKey: 'POST /channels/:id/messages/bulk-delete',
        body: {'message_ids': messageIds.map((id) => id.toJson()).toList()},
      );

  /// Adds a reaction to a message, as the bot. [emoji] is either a raw
  /// Unicode emoji character or a custom emoji in `name:id` form —
  /// whatever the wire format expects, verified against the OpenAPI
  /// spec's `{emoji}` path parameter (an opaque string, not a structured
  /// object).
  Future<void> addReaction(
    Snowflake channelId,
    Snowflake messageId,
    String emoji,
  ) => _client.requestJson(
    method: 'PUT',
    path:
        '/channels/$channelId/messages/$messageId/reactions/'
        '${Uri.encodeComponent(emoji)}/@me',
    bucketKey: 'PUT /channels/:id/messages/:id/reactions/:emoji/@me',
  );
}
