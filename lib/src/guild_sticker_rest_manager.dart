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

  /// [image] is a data URI (`data:image/png;base64,...`), matching what
  /// `GuildStickerCreateRequest.image` expects on the wire.
  Future<GuildSticker> create(
    Snowflake guildId, {
    required String name,
    required String image,
    String? description,
    String? tags,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/stickers',
      bucketKey: 'POST /guilds/:id/stickers',
      body: {
        'name': name,
        'image': image,
        'description': ?description,
        'tags': ?tags,
      },
    );
    return GuildSticker.fromJson(json!);
  }

  Future<GuildSticker> clone(
    Snowflake guildId,
    Snowflake sourceStickerId,
  ) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/stickers/clone',
      bucketKey: 'POST /guilds/:id/stickers/clone',
      body: {'source_sticker_id': sourceStickerId.toJson()},
    );
    return GuildSticker.fromJson(json!);
  }

  Future<void> delete(
    Snowflake guildId,
    Snowflake stickerId, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'DELETE',
    path: '/guilds/$guildId/stickers/$stickerId',
    bucketKey: 'DELETE /guilds/:id/stickers/:id',
    auditLogReason: auditLogReason,
  );
}
