import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// Invite REST calls, mirroring Fluxer's own `/invites/{code}`,
/// `/channels/{id}/invites`, and `/guilds/{id}/invites` OpenAPI groupings.
final class InviteRestManager {
  const InviteRestManager(this._client);

  final RestClient _client;

  Future<List<Invite>> listForGuild(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/invites',
      bucketKey: 'GET /guilds/:id/invites',
    );
    return (json as List<dynamic>)
        .map((i) => Invite.fromJson(i as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Invite> get(String code) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/invites/$code',
      bucketKey: 'GET /invites/:code',
    );
    return Invite.fromJson(json!);
  }

  /// [maxUses] and [maxAge] are `0` for unlimited/never-expiring per
  /// Fluxer's `ChannelInviteCreateRequest`, not `null` — `null` here
  /// means "let the server pick its default" and simply omits the field.
  Future<Invite> createForChannel(
    Snowflake channelId, {
    int? maxUses,
    int? maxAge,
    bool? unique,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/invites',
      bucketKey: 'POST /channels/:id/invites',
      body: {'max_uses': ?maxUses, 'max_age': ?maxAge, 'unique': ?unique},
    );
    return Invite.fromJson(json!);
  }

  Future<void> delete(String code) => _client.requestJson(
    method: 'DELETE',
    path: '/invites/$code',
    bucketKey: 'DELETE /invites/:code',
  );

  Future<List<Invite>> listForChannel(Snowflake channelId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/invites',
      bucketKey: 'GET /channels/:id/invites',
    );
    return (json as List<dynamic>)
        .map((i) => Invite.fromJson(i as Map<String, dynamic>))
        .toList(growable: false);
  }
}
