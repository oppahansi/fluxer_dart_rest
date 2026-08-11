import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// Guild emoji REST calls, mirroring Fluxer's own `/guilds/{id}/emojis`
/// OpenAPI grouping. Like bans, there's no single-emoji-fetch endpoint —
/// only list, patch, and delete — so getting one specific emoji means
/// filtering [list].
final class GuildEmojiRestManager {
  const GuildEmojiRestManager(this._client);

  final RestClient _client;

  Future<List<GuildEmoji>> list(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/emojis',
      bucketKey: 'GET /guilds/:id/emojis',
    );
    return (json as List<dynamic>)
        .map((e) => GuildEmoji.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
