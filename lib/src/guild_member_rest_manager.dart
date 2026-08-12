import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// Guild member REST calls, mirroring Fluxer's own
/// `/guilds/{id}/members` OpenAPI grouping. Note there's no single-ban-fetch
/// endpoint on the server (`/guilds/{id}/bans/{user_id}` is PUT/DELETE
/// only) — see [GuildBanRestManager] for the equivalent ban calls.
final class GuildMemberRestManager {
  const GuildMemberRestManager(this._client);

  final RestClient _client;

  /// [limit] must be sent explicitly — confirmed against the live
  /// OpenAPI spec that Fluxer defaults it to **1** if omitted, not "all"
  /// or some larger page size like every other list endpoint in this
  /// SDK. [after] pages through guilds with more than [limit] members
  /// (max 1000 per call), same cursor convention as everywhere else on
  /// the platform.
  Future<List<GuildMember>> list(
    Snowflake guildId, {
    int limit = 100,
    Snowflake? after,
  }) async {
    final json = await _client.requestJson(
      method: 'GET',
      path:
          '/guilds/$guildId/members?limit=$limit'
          '${after == null ? '' : '&after=$after'}',
      bucketKey: 'GET /guilds/:id/members',
    );
    return (json as List<dynamic>)
        .map((m) => GuildMember.fromJson(m as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<GuildMember> get(Snowflake guildId, Snowflake userId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/members/$userId',
      bucketKey: 'GET /guilds/:id/members/:id',
    );
    return GuildMember.fromJson(json!);
  }

  Future<void> kick(Snowflake guildId, Snowflake userId) => _client.requestJson(
    method: 'DELETE',
    path: '/guilds/$guildId/members/$userId',
    bucketKey: 'DELETE /guilds/:id/members/:id',
  );

  /// Times a member out until [until], or clears an existing timeout when
  /// [until] is `null`.
  Future<GuildMember> timeout(
    Snowflake guildId,
    Snowflake userId, {
    required DateTime? until,
    String? reason,
  }) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/guilds/$guildId/members/$userId',
      bucketKey: 'PATCH /guilds/:id/members/:id',
      body: {
        'communication_disabled_until': until?.toIso8601String(),
        'timeout_reason': ?reason,
      },
    );
    return GuildMember.fromJson(json!);
  }

  Future<void> addRole(Snowflake guildId, Snowflake userId, Snowflake roleId) =>
      _client.requestJson(
        method: 'PUT',
        path: '/guilds/$guildId/members/$userId/roles/$roleId',
        bucketKey: 'PUT /guilds/:id/members/:id/roles/:id',
      );

  Future<void> removeRole(
    Snowflake guildId,
    Snowflake userId,
    Snowflake roleId,
  ) => _client.requestJson(
    method: 'DELETE',
    path: '/guilds/$guildId/members/$userId/roles/$roleId',
    bucketKey: 'DELETE /guilds/:id/members/:id/roles/:id',
  );
}
