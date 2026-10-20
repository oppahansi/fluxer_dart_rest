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

  /// [userId]'s profile. Naming a [guildId] adds their member and guild
  /// profile there; [withMutualGuilds] adds the guilds this bot shares
  /// with them.
  Future<UserProfile> profile(
    Snowflake userId, {
    Snowflake? guildId,
    bool withMutualGuilds = false,
  }) async {
    final query = [
      if (guildId != null) 'guild_id=$guildId',
      if (withMutualGuilds) 'with_mutual_guilds=true',
    ].join('&');
    final json = await _client.requestJson(
      method: 'GET',
      path: '/users/$userId/profile${query.isEmpty ? '' : '?$query'}',
      bucketKey: 'GET /users/:id/profile',
    );
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  /// The application this bot belongs to.
  Future<BotApplication> application() async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/applications/@me',
      bucketKey: 'GET /applications/@me',
    );
    return BotApplication.fromJson(json as Map<String, dynamic>);
  }

  /// Deletes **every** message this bot has sent in [guildId], in every
  /// channel, in the background.
  ///
  /// The route asks a user for sudo verification; a bot token is not
  /// asked, so this runs at once with no confirmation and cannot be
  /// undone.
  Future<void> deleteAllOwnMessagesInGuild(Snowflake guildId) =>
      _client.requestJson(
        method: 'POST',
        path: '/users/@me/guilds/$guildId/messages/bulk-delete-mine',
        bucketKey: 'POST /users/@me/guilds/:id/messages/bulk-delete-mine',
        body: const <String, dynamic>{},
      );
}
