import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// The `/gateway/*` OpenAPI grouping — currently just the one call a bot
/// actually needs before connecting.
final class GatewayRestManager {
  const GatewayRestManager(this._client);

  final RestClient _client;

  /// Where to connect the gateway WebSocket, and this bot's current
  /// session-start allowance. Always call this fresh right before
  /// connecting — see [GatewayBotInfo]'s doc comment for why.
  Future<GatewayBotInfo> getBotGatewayInfo() async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/gateway/bot',
      bucketKey: 'GET /gateway/bot',
    );
    return GatewayBotInfo.fromJson(json!);
  }
}
