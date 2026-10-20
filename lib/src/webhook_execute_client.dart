import 'dart:convert';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'http_transport.dart';
import 'package_http_transport.dart';
import 'rest_client.dart';

/// Everything a webhook token alone can do: post as the webhook, edit or
/// delete what it posted, and read, rename or delete the webhook itself.
///
/// Separate from [RestClient] because these routes authenticate with the
/// webhook token in their own path and carry no security requirement:
/// [RestClient] always sends `Authorization: Bot <token>`, which these
/// requests must not include. Anyone holding the token can call them, so
/// it needs no bot at all.
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

  /// Posts a message as the webhook without waiting for it to be stored.
  ///
  /// [threadId] posts into a thread of the webhook's channel. In a forum
  /// or media channel, [threadName] creates a new post instead, with
  /// [appliedTagIds] (at most 5) as its tags.
  Future<void> execute(
    Snowflake webhookId,
    String token, {
    String? content,
    List<Embed> embeds = const [],
    String? username,
    String? avatarUrl,
    AllowedMentions? allowedMentions,
    Snowflake? threadId,
    String? threadName,
    List<Snowflake> appliedTagIds = const [],
  }) => _send(
    'POST',
    '$webhookId/$token${_query(wait: false, threadId: threadId)}',
    _messageBody(
      content: content,
      embeds: embeds,
      username: username,
      avatarUrl: avatarUrl,
      allowedMentions: allowedMentions,
      threadName: threadName,
      appliedTagIds: appliedTagIds,
    ),
  );

  /// Like [execute], but waits for the message to be stored and returns
  /// it, so it can be edited or deleted later with the same token.
  Future<Message> executeAndWait(
    Snowflake webhookId,
    String token, {
    String? content,
    List<Embed> embeds = const [],
    String? username,
    String? avatarUrl,
    AllowedMentions? allowedMentions,
    Snowflake? threadId,
    String? threadName,
    List<Snowflake> appliedTagIds = const [],
  }) async {
    final json = await _send(
      'POST',
      '$webhookId/$token${_query(wait: true, threadId: threadId)}',
      _messageBody(
        content: content,
        embeds: embeds,
        username: username,
        avatarUrl: avatarUrl,
        allowedMentions: allowedMentions,
        threadName: threadName,
        appliedTagIds: appliedTagIds,
      ),
    );
    return Message.fromJson(json as Map<String, dynamic>);
  }

  /// A message this webhook posted. [threadId] is needed when it was
  /// posted into a thread.
  Future<Message> getMessage(
    Snowflake webhookId,
    String token,
    Snowflake messageId, {
    Snowflake? threadId,
  }) async {
    final json = await _send(
      'GET',
      '$webhookId/$token/messages/$messageId${_query(threadId: threadId)}',
    );
    return Message.fromJson(json as Map<String, dynamic>);
  }

  /// Edits a message this webhook posted. Only the fields given change.
  Future<Message> editMessage(
    Snowflake webhookId,
    String token,
    Snowflake messageId, {
    String? content,
    List<Embed>? embeds,
    AllowedMentions? allowedMentions,
    Snowflake? threadId,
  }) async {
    final json = await _send(
      'PATCH',
      '$webhookId/$token/messages/$messageId${_query(threadId: threadId)}',
      {
        'content': ?content,
        if (embeds != null) 'embeds': [for (final e in embeds) e.toJson()],
        if (allowedMentions != null)
          'allowed_mentions': allowedMentions.toJson(),
      },
    );
    return Message.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteMessage(
    Snowflake webhookId,
    String token,
    Snowflake messageId, {
    Snowflake? threadId,
  }) => _send(
    'DELETE',
    '$webhookId/$token/messages/$messageId${_query(threadId: threadId)}',
  );

  /// The webhook itself. A token-authenticated read has no
  /// [Webhook.creator].
  Future<Webhook> get(Snowflake webhookId, String token) async {
    final json = await _send('GET', '$webhookId/$token');
    return Webhook.fromJson(json as Map<String, dynamic>);
  }

  /// Renames the webhook or replaces its avatar (a data URI, or `null` to
  /// remove it). Moving it to another channel needs the bot route.
  Future<Webhook> update(
    Snowflake webhookId,
    String token, {
    String? name,
    String? Function()? avatar,
  }) async {
    final json = await _send('PATCH', '$webhookId/$token', {
      'name': ?name,
      if (avatar != null) 'avatar': avatar(),
    });
    return Webhook.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(Snowflake webhookId, String token) =>
      _send('DELETE', '$webhookId/$token');

  static Map<String, dynamic> _messageBody({
    required String? content,
    required List<Embed> embeds,
    required String? username,
    required String? avatarUrl,
    required AllowedMentions? allowedMentions,
    required String? threadName,
    required List<Snowflake> appliedTagIds,
  }) => {
    'content': ?content,
    if (embeds.isNotEmpty) 'embeds': embeds.map((e) => e.toJson()).toList(),
    'username': ?username,
    'avatar_url': ?avatarUrl,
    if (allowedMentions != null) 'allowed_mentions': allowedMentions.toJson(),
    'thread_name': ?threadName,
    if (appliedTagIds.isNotEmpty)
      'applied_tags': [for (final id in appliedTagIds) id.toJson()],
  };

  static String _query({bool? wait, Snowflake? threadId}) {
    final params = [
      if (wait ?? false) 'wait=true',
      if (threadId != null) 'thread_id=$threadId',
    ];
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  Future<dynamic> _send(
    String method,
    String route, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _transport.send(
      HttpTransportRequest(
        method: method,
        path: '/$apiVersion/webhooks/$route',
        body: body,
        headers: body == null
            ? const {}
            : const {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode >= 400) {
      final decoded = response.body.isEmpty
          ? null
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw FluxerApiException(
        (decoded?['message'] as String?) ?? 'Webhook $method failed',
        statusCode: response.statusCode,
        errorCode: decoded?['code'] as String?,
        fieldErrors: FluxerFieldError.listFromJson(decoded?['errors']),
      );
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }
}
