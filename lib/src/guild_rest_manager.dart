import 'package:fluxer_core/fluxer_core.dart';

import 'rest_client.dart';

/// Guild-resource REST calls, mirroring Fluxer's own `/guilds/*` OpenAPI
/// grouping (Repository pattern: returns typed [Guild]s, not raw JSON).
final class GuildRestManager {
  const GuildRestManager(this._client);

  final RestClient _client;

  Future<Guild> get(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId',
      bucketKey: 'GET /guilds/:id',
    );
    return Guild.fromJson(json!);
  }
}
