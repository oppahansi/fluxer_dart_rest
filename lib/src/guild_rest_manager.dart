import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'channel_create_builder.dart';
import 'position_update.dart';
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

  /// Every channel in [guildId] this bot can view, threads excluded.
  Future<List<Channel>> listChannels(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/channels',
      bucketKey: 'GET /guilds/:id/channels',
    );
    return (json as List<dynamic>)
        .map((c) => Channel.fromJson(c as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Moves several channels in one request. Answered by one or more
  /// `CHANNEL_UPDATE_BULK` dispatches carrying the resulting positions.
  Future<void> updateChannelPositions(
    Snowflake guildId,
    List<ChannelPositionUpdate> positions, {
    String? auditLogReason,
  }) => _client.requestJson(
    method: 'PATCH',
    path: '/guilds/$guildId/channels',
    bucketKey: 'PATCH /guilds/:id/channels',
    body: positions.map((p) => p.toJson()).toList(growable: false),
    auditLogReason: auditLogReason,
  );

  Future<Channel> createChannel(
    Snowflake guildId,
    ChannelCreateBuilder channel,
  ) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/channels',
      bucketKey: 'POST /guilds/:id/channels',
      body: channel.toJson(),
    );
    return Channel.fromJson(json!);
  }

  /// Lists up to [limit] recent audit log entries, newest first.
  Future<List<GuildAuditLogEntry>> getAuditLogs(
    Snowflake guildId, {
    int? limit,
  }) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: limit == null
          ? '/guilds/$guildId/audit-logs'
          : '/guilds/$guildId/audit-logs?limit=$limit',
      bucketKey: 'GET /guilds/:id/audit-logs',
    );
    final entries =
        (json as Map<String, dynamic>)['audit_log_entries'] as List<dynamic>;
    return entries
        .map((e) => GuildAuditLogEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Updates guild settings.
  ///
  /// [changes] holds raw request fields (`name`, `icon`, `system_channel_id`,
  /// ...); omitting a field leaves it unchanged.
  Future<Guild> update(
    Snowflake guildId,
    Map<String, dynamic> changes, {
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/guilds/$guildId',
      bucketKey: 'PATCH /guilds/:id',
      body: changes,
      auditLogReason: auditLogReason,
    );
    return Guild.fromJson(json!);
  }

  /// Lists every webhook in the guild, across all its channels.
  Future<List<Webhook>> webhooks(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/webhooks',
      bucketKey: 'GET /guilds/:id/webhooks',
    );
    return (json as List<dynamic>)
        .map((w) => Webhook.fromJson(w as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Reads the guild's vanity invite code and how often it has been used.
  ///
  /// Returns a null code when the guild has no vanity URL set.
  Future<({String? code, int uses})> vanityUrl(Snowflake guildId) async {
    final json =
        await _client.requestJson(
              method: 'GET',
              path: '/guilds/$guildId/vanity-url',
              bucketKey: 'GET /guilds/:id/vanity-url',
            )
            as Map<String, dynamic>;
    return (code: json['code'] as String?, uses: json['uses'] as int? ?? 0);
  }

  /// Searches guild members by username, global name or nickname.
  ///
  /// Backed by a search index rather than the member list, so it returns
  /// [GuildMemberSearchResult]s and can answer while the index is still
  /// building — check [GuildMemberSearchPage.indexing] before treating an
  /// empty result as authoritative. Unlike
  /// `GuildMemberRestManager.list`, this pages by [offset] rather than by
  /// a snowflake cursor.
  Future<GuildMemberSearchPage> searchMembers(
    Snowflake guildId, {
    String? query,
    int limit = 25,
    int offset = 0,
    List<Snowflake> roleIds = const [],
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/members-search',
      bucketKey: 'POST /guilds/:id/members-search',
      body: {
        'query': ?query,
        'limit': limit,
        if (offset > 0) 'offset': offset,
        if (roleIds.isNotEmpty)
          'role_ids': roleIds.map((r) => r.toJson()).toList(growable: false),
      },
    );
    return GuildMemberSearchPage.fromJson(json! as Map<String, dynamic>);
  }
}
