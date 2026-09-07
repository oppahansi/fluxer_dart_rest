import 'dart:convert';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:http/http.dart' as http;

/// Reads a deployment's discovery document.
///
/// Separate from the other managers because it is the one call made
/// before a [RestClient][] exists: it is unauthenticated, unversioned,
/// and its whole purpose is to find the origins every later request uses.
/// Pointing a bot at a self-hosted instance means resolving the domain
/// here first, then building the client from
/// [InstanceEndpoints.apiPublic] and connecting the gateway to
/// [InstanceEndpoints.gateway].
///
/// [RestClient]: package:fluxer_dart_rest/src/rest_httpClient.dart
final class InstanceRestManager {
  const InstanceRestManager({http.Client? client}) : _httpClient = client;

  final http.Client? _httpClient;

  /// Fetches `/.well-known/fluxer` from [origin].
  ///
  /// [origin] is the deployment's public origin, such as
  /// `https://fluxer.app` — not an API base URL, since the document sits
  /// at the site root and carries no version prefix.
  Future<InstanceDiscovery> discover(Uri origin) async {
    final client = _httpClient ?? http.Client();
    try {
      final response = await client.get(
        origin.replace(path: '/.well-known/fluxer'),
      );
      if (response.statusCode >= 400) {
        throw FluxerApiException(
          'Instance discovery failed for $origin',
          statusCode: response.statusCode,
        );
      }
      return InstanceDiscovery.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } finally {
      if (_httpClient == null) client.close();
    }
  }
}
