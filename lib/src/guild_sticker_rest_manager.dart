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
  /// `GuildStickerCreateRequest.image` expects on the wire. [tags] are
  /// autocomplete suggestions: at most 10, each 1-30 characters.
  Future<GuildSticker> create(
    Snowflake guildId, {
    required String name,
    required String image,
    String? description,
    List<String> tags = const [],
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/stickers',
      bucketKey: 'POST /guilds/:id/stickers',
      body: {
        'name': name,
        'image': image,
        'description': ?description,
        if (tags.isNotEmpty) 'tags': tags,
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

  /// The guild a sticker belongs to, for a sticker used from another
  /// guild.
  Future<PartialGuild> source(Snowflake stickerId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/stickers/$stickerId/source',
      bucketKey: 'GET /stickers/:id/source',
    );
    return PartialGuild.fromJson(json! as Map<String, dynamic>);
  }

  /// Renames a sticker and replaces its tags. The API requires [name] on
  /// every update.
  Future<GuildSticker> update(
    Snowflake guildId,
    Snowflake stickerId, {
    required String name,
    List<String>? tags,
  }) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/guilds/$guildId/stickers/$stickerId',
      bucketKey: 'PATCH /guilds/:id/stickers/:id',
      body: {'name': name, 'tags': ?tags},
    );
    return GuildSticker.fromJson(json as Map<String, dynamic>);
  }

  /// Creates up to 50 stickers. An invalid entry rejects the whole
  /// request before anything is created.
  Future<BulkCreateResult<GuildSticker>> bulkCreate(
    Snowflake guildId,
    List<({String name, String image, String? description, List<String> tags})>
    stickers,
  ) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/stickers/bulk',
      bucketKey: 'POST /guilds/:id/stickers/bulk',
      body: {
        'stickers': [
          for (final s in stickers)
            {
              'name': s.name,
              'image': s.image,
              'description': ?s.description,
              if (s.tags.isNotEmpty) 'tags': s.tags,
            },
        ],
      },
    );
    return BulkCreateResult.fromJson(
      json as Map<String, dynamic>,
      GuildSticker.fromJson,
    );
  }

  /// Any sticker's guild and cloning permission, from its id alone.
  Future<ExpressionMetadata> metadata(Snowflake stickerId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/stickers/$stickerId/metadata',
      bucketKey: 'GET /stickers/:id/metadata',
    );
    return ExpressionMetadata.fromJson(json as Map<String, dynamic>);
  }
}
