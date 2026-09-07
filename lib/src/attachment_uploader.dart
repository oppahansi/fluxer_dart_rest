import 'dart:typed_data';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:http/http.dart' as http;

/// Transfers attachment bytes to a presigned storage URL.
///
/// Separate from [HttpTransport][] because these requests do not go to
/// the API at all: the URL is absolute, points at storage or an upload
/// relay, carries its own signature in the query string, and must not
/// receive the bot's `Authorization` header. Kept behind an interface so
/// tests can drive the upload flow without a network.
///
/// [HttpTransport]: package:fluxer_dart_rest/src/http_transport.dart
abstract interface class AttachmentUploader {
  /// Sends [bytes] with `PUT`. [url] must be used exactly as issued —
  /// altering the query string invalidates the signature.
  Future<void> put(Uri url, Uint8List bytes, String contentType);
}

/// [AttachmentUploader] backed by `package:http`.
final class PackageHttpAttachmentUploader implements AttachmentUploader {
  const PackageHttpAttachmentUploader({http.Client? client})
    : _httpClient = client;

  final http.Client? _httpClient;

  @override
  Future<void> put(Uri url, Uint8List bytes, String contentType) async {
    final client = _httpClient ?? http.Client();
    try {
      final response = await client.put(
        url,
        headers: {'Content-Type': contentType},
        body: bytes,
      );
      if (response.statusCode >= 400) {
        throw FluxerApiException(
          'Attachment upload failed',
          statusCode: response.statusCode,
        );
      }
    } finally {
      if (_httpClient == null) client.close();
    }
  }
}
