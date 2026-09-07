import 'dart:convert';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'http_transport.dart';
import 'package_http_transport.dart';
import 'rest_client.dart';

/// Sends messages through `POST /webhooks/{id}/{token}`.
///
/// Separate from [RestClient] because the route authenticates with the
/// webhook token in its own path and carries no security requirement:
/// [RestClient] always sends `Authorization: Bot <token>`, which this
/// request must not include.
///
/// Covers `content`, `embeds`, `username` and `avatarUrl`. The route also
/// accepts attachments, allowed mentions and stickers, which are not
/// modelled here.
final class WebhookExecuteClient {
  WebhookExecuteClient({
    HttpTransport? transport,
    Uri? baseUrl,
    this.apiVersion = defaultFluxerApiVersion,
  }) : _transport =
           transport ??
           PackageHttpTransport(baseUrl: baseUrl ?? defaultFluxerApiBaseUrl);

  final HttpTransport _transport;

  /// Path segment prepended to the request path, matching
  /// [RestClient.apiVersion].
  final String apiVersion;

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
        path: '/$apiVersion/webhooks/$webhookId/$token',
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
