import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'channel_create_builder.dart';
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
}
