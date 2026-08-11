import 'package:fluxer_core/fluxer_core.dart';

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

  Future<void> delete(Snowflake guildId, Snowflake roleId) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/guilds/$guildId/roles/$roleId',
        bucketKey: 'DELETE /guilds/:id/roles/:id',
      );
}
