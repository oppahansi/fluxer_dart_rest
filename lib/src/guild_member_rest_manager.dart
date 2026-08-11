import 'package:fluxer_core/fluxer_core.dart';

import 'rest_client.dart';

/// Guild member REST calls, mirroring Fluxer's own
/// `/guilds/{id}/members` OpenAPI grouping. Note there's no single-ban-fetch
/// endpoint on the server (`/guilds/{id}/bans/{user_id}` is PUT/DELETE
/// only) — see [GuildBanRestManager] for the equivalent ban calls.
final class GuildMemberRestManager {
  const GuildMemberRestManager(this._client);

  final RestClient _client;

  Future<List<GuildMember>> list(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/members',
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
}
