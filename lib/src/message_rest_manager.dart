import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'message_builder.dart';
import 'rest_client.dart';

/// Message-resource REST calls, mirroring Fluxer's own
/// `/channels/{id}/messages` OpenAPI grouping.
final class MessageRestManager {
  const MessageRestManager(this._client);

  final RestClient _client;

  Future<Message> send(Snowflake channelId, MessageBuilder message) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/messages',
      bucketKey: 'POST /channels/:id/messages',
      body: message.toJson(),
    );
    return Message.fromJson(json!);
  }
}
