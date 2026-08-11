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

  /// [image] is a data URI (`data:image/png;base64,...`), matching what
  /// `GuildEmojiCreateRequest.image` expects on the wire.
  Future<GuildEmoji> create(
    Snowflake guildId, {
    required String name,
    required String image,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/emojis',
      bucketKey: 'POST /guilds/:id/emojis',
      body: {'name': name, 'image': image},
    );
    return GuildEmoji.fromJson(json!);
  }

  Future<GuildEmoji> clone(Snowflake guildId, Snowflake sourceEmojiId) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/emojis/clone',
      bucketKey: 'POST /guilds/:id/emojis/clone',
      body: {'source_emoji_id': sourceEmojiId.toJson()},
    );
    return GuildEmoji.fromJson(json!);
  }

  Future<void> delete(Snowflake guildId, Snowflake emojiId) =>
      _client.requestJson(
        method: 'DELETE',
        path: '/guilds/$guildId/emojis/$emojiId',
        bucketKey: 'DELETE /guilds/:id/emojis/:id',
      );
}
