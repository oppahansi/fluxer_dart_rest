import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_transport.dart';

/// [HttpTransport] backed by a real HTTP client, via the official
/// `package:http`.
final class PackageHttpTransport implements HttpTransport {
  PackageHttpTransport({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// No trailing slash (e.g. `https://api.fluxer.app`).
  final Uri baseUrl;

  final http.Client _client;

  @override
  Future<HttpTransportResponse> send(HttpTransportRequest request) async {
    final uri = Uri.parse('$baseUrl${request.path}');
    final body = request.body == null ? null : jsonEncode(request.body);

    final response = await switch (request.method) {
      'GET' => _client.get(uri, headers: request.headers),
      'POST' => _client.post(uri, headers: request.headers, body: body),
      'PATCH' => _client.patch(uri, headers: request.headers, body: body),
      'PUT' => _client.put(uri, headers: request.headers, body: body),
      'DELETE' => _client.delete(uri, headers: request.headers, body: body),
      _ => throw ArgumentError('Unsupported HTTP method: ${request.method}'),
    };

    return HttpTransportResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
    );
  }
}
