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
}
