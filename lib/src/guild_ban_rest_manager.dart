import 'package:fluxer_core/fluxer_core.dart';

import 'rest_client.dart';

/// Guild ban REST calls, mirroring Fluxer's own `/guilds/{id}/bans`
/// OpenAPI grouping. Note there's no single-ban-fetch endpoint on the
/// server — `/guilds/{id}/bans/{user_id}` is PUT (ban) and DELETE (unban)
/// only, so getting one specific ban means filtering [list].
final class GuildBanRestManager {
  const GuildBanRestManager(this._client);

  final RestClient _client;

  Future<List<GuildBan>> list(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/bans',
      bucketKey: 'GET /guilds/:id/bans',
    );
    return (json as List<dynamic>)
        .map((b) => GuildBan.fromJson(b as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> ban(Snowflake guildId, Snowflake userId, {String? reason}) =>
      _client.requestJson(
        method: 'PUT',
        path: '/guilds/$guildId/bans/$userId',
        bucketKey: 'PUT /guilds/:id/bans/:id',
        body: reason == null ? const <String, dynamic>{} : {'reason': reason},
      );

  Future<void> unban(Snowflake guildId, Snowflake userId) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/guilds/$guildId/bans/$userId',
        bucketKey: 'DELETE /guilds/:id/bans/:id',
      );
}
