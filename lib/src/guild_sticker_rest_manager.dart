import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// Guild sticker REST calls, mirroring Fluxer's own
/// `/guilds/{id}/stickers` OpenAPI grouping. Same shape as
/// [GuildEmojiRestManager]: list only, no single-sticker-fetch endpoint.
final class GuildStickerRestManager {
  const GuildStickerRestManager(this._client);

  final RestClient _client;

  Future<List<GuildSticker>> list(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/stickers',
      bucketKey: 'GET /guilds/:id/stickers',
    );
    return (json as List<dynamic>)
        .map((s) => GuildSticker.fromJson(s as Map<String, dynamic>))
        .toList(growable: false);
  }
}
