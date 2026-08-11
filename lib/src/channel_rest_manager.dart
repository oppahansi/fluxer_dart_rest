import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// Channel-resource REST calls, mirroring Fluxer's own `/channels/*`
/// OpenAPI grouping.
final class ChannelRestManager {
  const ChannelRestManager(this._client);

  final RestClient _client;

  Future<Channel> get(Snowflake channelId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/channels/$channelId',
      bucketKey: 'GET /channels/:id',
    );
    return Channel.fromJson(json!);
  }
}
