import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'guild_role_update_builder.dart';
import 'rest_client.dart';

/// Guild role REST calls, mirroring Fluxer's own `/guilds/{id}/roles`
/// OpenAPI grouping.
final class GuildRoleRestManager {
  const GuildRoleRestManager(this._client);

  final RestClient _client;

  Future<List<GuildRole>> list(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/roles',
      bucketKey: 'GET /guilds/:id/roles',
    );
    return (json as List<dynamic>)
        .map((r) => GuildRole.fromJson(r as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<GuildRole> create(
    Snowflake guildId, {
    required String name,
    int? color,
    Permissions? permissions,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/roles',
      bucketKey: 'POST /guilds/:id/roles',
      body: {
        'name': name,
        'color': ?color,
        if (permissions != null) 'permissions': permissions.toJson(),
      },
    );
    return GuildRole.fromJson(json!);
  }

  Future<void> delete(
    Snowflake guildId,
    Snowflake roleId, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'DELETE',
    path: '/guilds/$guildId/roles/$roleId',
    bucketKey: 'DELETE /guilds/:id/roles/:id',
    auditLogReason: auditLogReason,
  );

  Future<GuildRole> update(
    Snowflake guildId,
    Snowflake roleId,
    GuildRoleUpdateBuilder update, {
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/guilds/$guildId/roles/$roleId',
      bucketKey: 'PATCH /guilds/:id/roles/:id',
      body: update.toJson(),
      auditLogReason: auditLogReason,
    );
    return GuildRole.fromJson(json!);
  }

  /// Reorders roles; a higher position ranks higher. Answered by a
  /// `GUILD_ROLE_UPDATE_BULK` carrying every role that moved.
  Future<void> updatePositions(
    Snowflake guildId,
    Map<Snowflake, int> positions, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'PATCH',
    path: '/guilds/$guildId/roles',
    bucketKey: 'PATCH /guilds/:id/roles',
    body: [
      for (final MapEntry(:key, :value) in positions.entries)
        {'id': key.toJson(), 'position': value},
    ],
    auditLogReason: auditLogReason,
  );

  /// Orders the hoisted groups in the member list independently of role
  /// positions. See [GuildRole.hoistPosition].
  Future<void> updateHoistPositions(
    Snowflake guildId,
    Map<Snowflake, int> hoistPositions, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'PATCH',
    path: '/guilds/$guildId/roles/hoist-positions',
    bucketKey: 'PATCH /guilds/:id/roles/hoist-positions',
    body: [
      for (final MapEntry(:key, :value) in hoistPositions.entries)
        {'id': key.toJson(), 'hoist_position': value},
    ],
    auditLogReason: auditLogReason,
  );

  /// Clears every role's hoist position, so the member list follows role
  /// positions again.
  Future<void> resetHoistPositions(
    Snowflake guildId, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'DELETE',
    path: '/guilds/$guildId/roles/hoist-positions',
    bucketKey: 'DELETE /guilds/:id/roles/hoist-positions',
    auditLogReason: auditLogReason,
  );
}
