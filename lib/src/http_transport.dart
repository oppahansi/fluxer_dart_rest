/// A single outgoing HTTP request. [path] is relative to the transport's
/// base URL (e.g. `/guilds/123`), never a full URL.
final class HttpTransportRequest {
  const HttpTransportRequest({
    required this.method,
    required this.path,
    this.body,
    this.headers = const {},
  });

  final String method;
  final String path;

  /// JSON-encodable body, or `null` for requests without one.
  final Object? body;

  final Map<String, String> headers;
}

final class HttpTransportResponse {
  const HttpTransportResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;

  /// Header names are lowercase, matching `package:http`'s convention.
  final Map<String, String> headers;

  /// Raw response body. Empty string for responses with no body (e.g. a
  /// `204 No Content`).
  final String body;
}

/// Abstracts the raw HTTP client so [RestClient][] doesn't depend on
/// `package:http` directly (Adapter pattern) — this is what lets tests
/// drive `RestClient` and everything built on it with a mocked transport
/// instead of live HTTP calls.
///
/// [RestClient]: package:fluxer_dart_rest/src/rest_client.dart
abstract interface class HttpTransport {
  Future<HttpTransportResponse> send(HttpTransportRequest request);
}
