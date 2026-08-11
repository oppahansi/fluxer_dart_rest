import 'package:fluxer_utils/fluxer_utils.dart';

/// Tracks a [TokenBucket] per route, populated *reactively* from
/// Fluxer's `X-RateLimit-Limit` / `X-RateLimit-Remaining` /
/// `X-RateLimit-Reset` response headers (verified present in Fluxer's
/// OpenAPI spec) rather than pre-configured with guessed capacities.
/// Fluxer doesn't publish per-route limits anywhere; the API's own
/// responses are the only honest source of truth.
///
/// Simplification worth revisiting in M2: this replaces a route's bucket
/// wholesale on every response rather than reconciling against the
/// existing one, and keys buckets by caller-supplied string rather than
/// Fluxer's actual per-route `X-RateLimit-Bucket` ID (which can group
/// multiple paths under one shared limit).
final class RateLimitBucketManager {
  final _buckets = <String, TokenBucket>{};

  /// How long to wait before it's safe to call [bucketKey] again. Zero if
  /// we haven't seen this route yet, or it currently has headroom.
  Duration waitTimeFor(String bucketKey) =>
      _buckets[bucketKey]?.waitTime ?? Duration.zero;

  void consume(String bucketKey) {
    _buckets[bucketKey]?.tryConsume();
  }

  /// Updates (or creates) the bucket for [bucketKey] from response
  /// headers. No-ops if the headers aren't present — some routes are
  /// unlimited and simply won't send them.
  void updateFromHeaders(String bucketKey, Map<String, String> headers) {
    final limit = int.tryParse(headers['x-ratelimit-limit'] ?? '');
    final remaining = int.tryParse(headers['x-ratelimit-remaining'] ?? '');
    final resetEpochSeconds = double.tryParse(
      headers['x-ratelimit-reset'] ?? '',
    );
    if (limit == null || remaining == null || resetEpochSeconds == null) return;

    final resetAt = DateTime.fromMillisecondsSinceEpoch(
      (resetEpochSeconds * 1000).round(),
      isUtc: true,
    );
    var refillPeriod = resetAt.difference(DateTime.now().toUtc());
    if (refillPeriod.isNegative) refillPeriod = const Duration(seconds: 1);

    _buckets[bucketKey] = TokenBucket(
      capacity: limit,
      refillPeriod: refillPeriod,
      initialTokens: remaining,
    );
  }
}
