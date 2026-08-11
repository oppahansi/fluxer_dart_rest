import 'dart:convert';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'http_transport.dart';
import 'package_http_transport.dart';
import 'rest_client.dart';

/// Sends messages through a webhook's token, per `POST
/// /webhooks/{id}/{token}` — confirmed against the live OpenAPI spec to
/// carry no `security` requirement at all, unlike every other route this
/// ecosystem talks to. Deliberately a separate class from [RestClient]
/// rather than an optional-token mode on it: [RestClient] always sends
/// `Authorization: Bot <token>`, and threading a "sometimes omit this
/// header" flag through it would make the common case (bot auth) harder
/// to read for the sake of this one different auth story.
///
/// Scoped to `content`/`embeds`/`username`/`avatarUrl` — the fields most
/// bots actually override — not the full `WebhookMessageRequest` schema
/// (attachments, allowed_mentions, stickers, etc. are out of scope, same
/// reasoning as [MessageBuilder]'s own scope cuts).
final class WebhookExecuteClient {
  WebhookExecuteClient({HttpTransport? transport, Uri? baseUrl})
    : _transport =
          transport ??
          PackageHttpTransport(baseUrl: baseUrl ?? defaultFluxerApiBaseUrl);

  final HttpTransport _transport;

  Future<void> execute(
    Snowflake webhookId,
    String token, {
    String? content,
    List<Embed> embeds = const [],
    String? username,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      'content': ?content,
      if (embeds.isNotEmpty) 'embeds': embeds.map((e) => e.toJson()).toList(),
      'username': ?username,
      'avatar_url': ?avatarUrl,
    };

    final response = await _transport.send(
      HttpTransportRequest(
        method: 'POST',
        path: '/webhooks/$webhookId/$token',
        body: body,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode >= 400) {
      final decoded = response.body.isEmpty
          ? null
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw FluxerApiException(
        (decoded?['message'] as String?) ?? 'Webhook execute failed',
        statusCode: response.statusCode,
        errorCode: decoded?['code'] as String?,
      );
    }
  }
}
