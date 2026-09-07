import 'dart:convert';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_utils/fluxer_dart_utils.dart';

import 'http_transport.dart';
import 'package_http_transport.dart';
import 'rate_limit_bucket_manager.dart';

/// Origin of Fluxer's hosted public API.
///
/// A self-hosted deployment publishes its own origin as
/// `endpoints.api_public` in its instance discovery document. The origin
/// carries no version segment; [RestClient] adds one per request.
final Uri defaultFluxerApiBaseUrl = Uri.parse('https://api.fluxer.app');

/// The only API version Fluxer currently serves.
///
/// Every route is also mounted at the origin root, but the versioned form
/// is the one clients are required to use.
const String defaultFluxerApiVersion = 'v1';

/// Low-level REST client: sends a request through [HttpTransport],
/// respects known rate-limit buckets, retries `429`/`5xx` responses, and
/// decodes JSON — everything above this (the resource managers) works in
/// typed `fluxer_dart_core` models instead of raw maps.
final class RestClient {
  RestClient({
    required this.token,
    HttpTransport? transport,
    Uri? baseUrl,
    Logger? logger,
    RetryPolicy? retryPolicy,
    this.apiVersion = defaultFluxerApiVersion,
  }) : transport =
           transport ??
           PackageHttpTransport(baseUrl: baseUrl ?? defaultFluxerApiBaseUrl),
       logger = logger ?? const NoopLogger(),
       retryPolicy =
           retryPolicy ?? ExponentialBackoffRetryPolicy(maxAttempts: 3);

  final String token;
  final HttpTransport transport;

  /// Path segment prepended to every request path, so managers can name
  /// routes the way the API reference does (`/users/@me`) while the
  /// request goes to the versioned mount (`/v1/users/@me`).
  final String apiVersion;
  final Logger logger;
  final RetryPolicy retryPolicy;

  final _rateLimits = RateLimitBucketManager();

  /// Sends a request and returns the decoded JSON body — a `Map` for
  /// single-resource endpoints, a `List` for list endpoints, or `null`
  /// for an empty response (e.g. `204 No Content`). Callers know which
  /// shape to expect from the route they called, same as any other
  /// untyped JSON client; the resource managers are what give call sites
  /// an actually-typed result.
  ///
  /// [bucketKey] identifies the rate-limit bucket this route belongs to
  /// — defaults to `"$method $path"`, which is wrong for routes that
  /// share a bucket (Fluxer's actual per-route bucket IDs aren't threaded
  /// through here), but never wrong in the unsafe direction: worst case
  /// it's more conservative than necessary.
  Future<dynamic> requestJson({
    required String method,
    required String path,
    String? bucketKey,
    Object? body,
    String? auditLogReason,
  }) async {
    final key = bucketKey ?? '$method $path';
    var attempt = 0;

    while (true) {
      attempt++;
      final wait = _rateLimits.waitTimeFor(key);
      if (wait > Duration.zero) {
        logger.debug(
          'Rate limit: waiting ${wait.inMilliseconds}ms before $method $path',
        );
        await Future<void>.delayed(wait);
      }

      final response = await transport.send(
        HttpTransportRequest(
          method: method,
          path: '/$apiVersion$path',
          body: body,
          headers: {
            'Authorization': 'Bot $token',
            'Content-Type': 'application/json',
            if (auditLogReason != null)
              'X-Audit-Log-Reason': _encodeAuditLogReason(auditLogReason),
          },
        ),
      );
      _rateLimits.updateFromHeaders(key, response.headers);
      _rateLimits.consume(key);

      if (response.statusCode == 429) {
        final retryAfterSeconds = double.tryParse(
          response.headers['retry-after'] ?? '',
        );
        final retryAfter = retryAfterSeconds != null
            ? Duration(milliseconds: (retryAfterSeconds * 1000).round())
            : retryPolicy.delayFor(attempt);
        if (!retryPolicy.shouldRetry(attempt)) {
          throw FluxerApiException(
            'Rate limited',
            statusCode: 429,
            errorCode: 'RATE_LIMITED',
            retryAfter: retryAfter,
          );
        }
        logger.warning(
          'Rate limited on $method $path, retrying in ${retryAfter.inMilliseconds}ms',
        );
        await Future<void>.delayed(retryAfter);
        continue;
      }

      if (response.statusCode >= 500 && retryPolicy.shouldRetry(attempt)) {
        await Future<void>.delayed(retryPolicy.delayFor(attempt));
        continue;
      }

      if (response.statusCode >= 400) {
        final decoded = _tryDecodeErrorBody(response.body);
        throw FluxerApiException(
          (decoded?['message'] as String?) ?? 'Request to $method $path failed',
          statusCode: response.statusCode,
          errorCode: decoded?['code'] as String?,
        );
      }

      return _tryDecode(response.body);
    }
  }

  /// Header values must be Latin-1; a reason may contain any Unicode. RFC
  /// 8187 percent-encoding is what the API expects for the wider range.
  static String _encodeAuditLogReason(String reason) =>
      Uri.encodeComponent(reason);

  dynamic _tryDecode(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  /// Fluxer's error responses are always a JSON object
  /// (`{code, message, ...}`), regardless of what the successful response
  /// shape for that route would have been — so this, unlike [_tryDecode],
  /// can safely assume a `Map`.
  Map<String, dynamic>? _tryDecodeErrorBody(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
