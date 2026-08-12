import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// User-resource REST calls, mirroring Fluxer's own `/users/@me/*`
/// OpenAPI grouping.
final class UserRestManager {
  const UserRestManager(this._client);

  final RestClient _client;

  /// Opens a DM channel with [recipientId] — or returns the existing one,
  /// if the two of you already have one. Confirmed against the live
  /// OpenAPI spec that `POST /users/@me/channels` accepts bot auth, same
  /// as every other route this package talks to.
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
