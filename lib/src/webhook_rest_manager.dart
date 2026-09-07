import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// Webhook REST calls, mirroring Fluxer's own `/channels/{id}/webhooks`
/// and `/webhooks/{id}` OpenAPI groupings.
final class WebhookRestManager {
  const WebhookRestManager(this._client);

  final RestClient _client;

  Future<List<Webhook>> listForChannel(Snowflake channelId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId/webhooks',
      bucketKey: 'GET /channels/:id/webhooks',
    );
    return (json as List<dynamic>)
        .map((w) => Webhook.fromJson(w as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Webhook> get(Snowflake webhookId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/webhooks/$webhookId',
      bucketKey: 'GET /webhooks/:id',
    );
    return Webhook.fromJson(json!);
  }

  Future<Webhook> createForChannel(
    Snowflake channelId, {
    required String name,
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/webhooks',
      bucketKey: 'POST /channels/:id/webhooks',
      body: {'name': name},
    );
    return Webhook.fromJson(json!);
  }

  Future<void> delete(Snowflake webhookId) => _client.requestJson(
    method: 'DELETE',
    path: '/webhooks/$webhookId',
    bucketKey: 'DELETE /webhooks/:id',
  );

  /// Updates a webhook's name, avatar, or channel.
  ///
  /// [changes] holds raw request fields; omitting one leaves it
  /// unchanged.
  Future<Webhook> update(
    Snowflake webhookId,
    Map<String, dynamic> changes, {
    String? auditLogReason,
  }) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/webhooks/$webhookId',
      bucketKey: 'PATCH /webhooks/:id',
      body: changes,
      auditLogReason: auditLogReason,
    );
    return Webhook.fromJson(json!);
  }
}
