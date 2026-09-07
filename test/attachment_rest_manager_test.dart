import 'dart:typed_data';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

/// Records what would have been transferred to storage, so the upload
/// flow can be driven without a network.
final class RecordingUploader implements AttachmentUploader {
  final puts = <({Uri url, int length, String contentType})>[];

  @override
  Future<void> put(Uri url, Uint8List bytes, String contentType) async {
    puts.add((url: url, length: bytes.length, contentType: contentType));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  late MockHttpTransport transport;
  late RecordingUploader uploader;
  late AttachmentRestManager manager;

  setUp(() {
    transport = MockHttpTransport();
    uploader = RecordingUploader();
    manager = AttachmentRestManager(
      RestClient(token: 't', transport: transport),
      uploader: uploader,
    );
  });

  void respondInOrder(List<String> bodies) {
    var call = 0;
    when(() => transport.send(any())).thenAnswer((_) async {
      final body = bodies[call < bodies.length ? call : bodies.length - 1];
      call++;
      return HttpTransportResponse(
        statusCode: 200,
        headers: const {},
        body: body,
      );
    });
  }

  test('plan posts the declarations and decodes a singlepart target', () async {
    respondInOrder([
      '{"attachments": [{"id": 0, "filename": "a.png", '
          '"upload_filename": "key-a", "file_size": 3, '
          '"content_type": "image/png", "upload_mode": "singlepart", '
          '"upload_url": "https://storage.invalid/put?sig=1"}]}',
    ]);

    final targets = await manager.plan(Snowflake.parse('2'), const [
      AttachmentUploadRequest(
        id: 0,
        filename: 'a.png',
        fileSize: 3,
        contentType: 'image/png',
      ),
    ]);

    final request =
        verify(() => transport.send(captureAny())).captured.single
            as HttpTransportRequest;
    expect(request.method, 'POST');
    expect(request.path, '/v1/channels/2/attachments');
    expect(request.body, {
      'attachments': [
        {
          'id': 0,
          'filename': 'a.png',
          'file_size': 3,
          'content_type': 'image/png',
        },
      ],
    });

    expect(targets.single, isA<AttachmentUploadSinglepart>());
    expect(targets.single.uploadFilename, 'key-a');
  });

  test('uploadFile plans, transfers once, and returns a claim', () async {
    respondInOrder([
      '{"attachments": [{"id": 0, "filename": "a.png", '
          '"upload_filename": "key-a", "file_size": 3, '
          '"content_type": "image/png", "upload_mode": "singlepart", '
          '"upload_url": "https://storage.invalid/put?sig=1"}]}',
    ]);

    final claim = await manager.uploadFile(
      Snowflake.parse('2'),
      filename: 'a.png',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/png',
      description: 'alt text',
    );

    expect(uploader.puts, hasLength(1));
    expect(
      uploader.puts.single.url.toString(),
      'https://storage.invalid/put?sig=1',
    );
    expect(uploader.puts.single.contentType, 'image/png');
    expect(claim.uploadFilename, 'key-a');
    expect(claim.toJson()['description'], 'alt text');
  });

  test('a multipart target is split by part size and then completed', () async {
    respondInOrder([
      '{"attachments": [{"id": 0, "filename": "big.bin", '
          '"upload_filename": "key-b", "file_size": 5, '
          '"content_type": "application/octet-stream", '
          '"upload_mode": "multipart", "upload_id": "u1", "part_size": 2, '
          '"parts": ['
          '{"part_number": 1, "upload_url": "https://storage.invalid/p1"},'
          '{"part_number": 2, "upload_url": "https://storage.invalid/p2"},'
          '{"part_number": 3, "upload_url": "https://storage.invalid/p3"}'
          ']}]}',
      '{"uploads": [{"upload_filename": "key-b"}]}',
    ]);

    await manager.uploadFile(
      Snowflake.parse('2'),
      filename: 'big.bin',
      bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      contentType: 'application/octet-stream',
    );

    // Five bytes at a part size of two: 2 + 2 + a short final part of 1.
    expect(uploader.puts.map((p) => p.length), [2, 2, 1]);

    final requests = verify(
      () => transport.send(captureAny()),
    ).captured.cast<HttpTransportRequest>();
    expect(requests.last.path, '/v1/channels/2/attachments/complete');
    expect(requests.last.body, {
      'uploads': [
        {'upload_filename': 'key-b', 'upload_id': 'u1'},
      ],
    });
  });
}
