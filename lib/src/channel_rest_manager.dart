import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'channel_update_builder.dart';
import 'rest_client.dart';

/// Channel-resource REST calls, mirroring Fluxer's own `/channels/*`
/// OpenAPI grouping. Channel *creation* lives on [GuildRestManager]
/// instead — `POST /guilds/{id}/channels` is guild-scoped, not
/// channel-scoped.
final class ChannelRestManager {
  const ChannelRestManager(this._client);

  final RestClient _client;

  Future<Channel> get(Snowflake channelId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId',
      bucketKey: 'GET /channels/:id',
    );
    return Channel.fromJson(json!);
  }

  Future<Channel> update(
    Snowflake channelId,
    ChannelUpdateBuilder update,
  ) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/channels/$channelId',
      bucketKey: 'PATCH /channels/:id',
      body: update.toJson(),
    );
    return Channel.fromJson(json!);
  }

  Future<void> delete(Snowflake channelId) => _client.requestJson(
    method: 'DELETE',
    path: '/channels/$channelId',
    bucketKey: 'DELETE /channels/:id',
  );

  /// Sets (creating or replacing) the permission overwrite for role or
  /// member [overwriteId] on this channel.
  Future<void> setPermissionOverwrite(
    Snowflake channelId,
    Snowflake overwriteId,
    PermissionOverwrite overwrite,
  ) => _client.requestJson(
    method: 'PUT',
    path: '/channels/$channelId/permissions/$overwriteId',
    bucketKey: 'PUT /channels/:id/permissions/:id',
    body: overwrite.toJson(),
  );

  Future<void> deletePermissionOverwrite(
    Snowflake channelId,
    Snowflake overwriteId,
  ) => _client.requestJson(
    method: 'DELETE',
    path: '/channels/$channelId/permissions/$overwriteId',
    bucketKey: 'DELETE /channels/:id/permissions/:id',
  );

  /// Reads how much longer the caller must wait before sending again in a
  /// slowmode channel.
  ///
  /// Returns zero when nothing is owed, including when the caller holds
  /// `bypassSlowmode`.
  Future<Duration> slowmodeWait(Snowflake channelId) async {
    final json =
        await _client.requestJson(
              method: 'GET',
              path: '/channels/$channelId/slowmode',
              bucketKey: 'GET /channels/:id/slowmode',
            )
            as Map<String, dynamic>;
    final seconds = json['wait_seconds'] ?? json['remaining'] ?? 0;
    return Duration(milliseconds: ((seconds as num) * 1000).round());
  }

  /// Adds a user to a group DM.
  ///
  /// Requires a solved captcha challenge. The API answers an unsolved
  /// request with `400 CAPTCHA_REQUIRED` and an ALTCHA proof-of-work
  /// challenge in the error body; solving it is the caller's job, and
  /// [captchaToken] carries the resulting base64 token.
  Future<void> addRecipient(
    Snowflake channelId,
    Snowflake userId, {
    String? captchaToken,
  }) => _client.requestJson(
    method: 'PUT',
    path: '/channels/$channelId/recipients/$userId',
    bucketKey: 'PUT /channels/:id/recipients/:id',
    captchaToken: captchaToken,
  );

  /// Removes a user from a group DM.
  Future<void> removeRecipient(Snowflake channelId, Snowflake userId) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/channels/$channelId/recipients/$userId',
        bucketKey: 'DELETE /channels/:id/recipients/:id',
      );

  /// Follows the announcement channel [channelId], delivering copies of
  /// its published messages into [targetChannelId].
  ///
  /// Creates a channel follower webhook in the target channel, named by
  /// [FollowedChannel.webhookId]; deleting that webhook stops following.
  /// Requires `viewChannel` on the announcement channel and
  /// `manageWebhooks` in the target.
  Future<FollowedChannel> follow(
    Snowflake channelId, {
    required Snowflake targetChannelId,
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/followers',
      bucketKey: 'POST /channels/:id/followers',
      body: {'webhook_channel_id': targetChannelId.toJson()},
      auditLogReason: auditLogReason,
    );
    return FollowedChannel.fromJson(json! as Map<String, dynamic>);
  }

  /// How many channels and guilds follow the announcement channel
  /// [channelId].
  Future<ChannelFollowerStats> followerStats(Snowflake channelId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/follower-stats',
      bucketKey: 'GET /channels/:id/follower-stats',
    );
    return ChannelFollowerStats.fromJson(json! as Map<String, dynamic>);
  }
}
