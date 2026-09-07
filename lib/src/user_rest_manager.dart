import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// User-resource REST calls, covering `/users/@me`, `/users/{id}` and
/// the private-channel routes.
final class UserRestManager {
  const UserRestManager(this._client);

  final RestClient _client;

  /// Fetches the account this token belongs to.
  Future<User> fetchCurrent() async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/users/@me',
      bucketKey: 'GET /users/@me',
    );
    return User.fromJson(json!);
  }

  /// Fetches any user by id.
  Future<User> fetch(Snowflake userId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/users/$userId',
      bucketKey: 'GET /users/:id',
    );
    return User.fromJson(json!);
  }

  /// Lists the guilds this account is in.
  Future<List<Guild>> guilds() async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/users/@me/guilds',
      bucketKey: 'GET /users/@me/guilds',
    );
    return (json as List<dynamic>)
        .map((g) => Guild.fromJson(g as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Leaves a guild. A bot cannot leave a guild it owns.
  Future<void> leaveGuild(Snowflake guildId) => _client.requestJson(
    method: 'DELETE',
    path: '/users/@me/guilds/$guildId',
    bucketKey: 'DELETE /users/@me/guilds/:id',
  );

  /// Lists the DM and group DM channels this account can see.
  Future<List<Channel>> privateChannels() async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/users/@me/channels',
      bucketKey: 'GET /users/@me/channels',
    );
    return (json as List<dynamic>)
        .map((c) => Channel.fromJson(c as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Opens a DM channel with [recipientId], or returns the existing one.
  Future<Channel> createDm(Snowflake recipientId) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/users/@me/channels',
      bucketKey: 'POST /users/@me/channels',
      body: {'recipient_id': recipientId.toJson()},
    );
    return Channel.fromJson(json!);
  }
}
