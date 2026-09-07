import 'dart:typed_data';

import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'attachment_uploader.dart';
import 'rest_client.dart';

/// The attachment upload flow.
///
/// Sending a file takes three steps, because the bytes never pass through
/// the API itself:
///
/// 1. [plan] declares the files and gets back presigned storage URLs.
/// 2. The bytes are transferred to those URLs, which [upload] does.
/// 3. A message send claims the result, via
///    `MessageBuilder.attachment`.
///
/// Nothing exists until step 3: an upload that is never claimed is
/// discarded, and each `upload_filename` can only be claimed once.
/// [uploadFile] runs the first two steps together for the common case.
final class AttachmentRestManager {
  AttachmentRestManager(this._client, {AttachmentUploader? uploader})
    : _uploader = uploader ?? const PackageHttpAttachmentUploader();

  /// The largest upload a bot token is granted, regardless of any higher
  /// limit the deployment resolves for other callers.
  static const int botMaxFileSize = 52428800;

  final RestClient _client;
  final AttachmentUploader _uploader;

  /// Declares 1-10 files and returns where to transfer each one.
  ///
  /// Results come back in request order, and each echoes the
  /// [AttachmentUploadRequest.id] it answers.
  Future<List<AttachmentUploadTarget>> plan(
    Snowflake channelId,
    List<AttachmentUploadRequest> attachments,
  ) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/channels/$channelId/attachments',
      bucketKey: 'POST /channels/:id/attachments',
      body: {
        'attachments': attachments
            .map((a) => a.toJson())
            .toList(growable: false),
      },
    );
    return ((json! as Map<String, dynamic>)['attachments'] as List<dynamic>)
        .map((a) => AttachmentUploadTarget.fromJson(a as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Transfers [bytes] to [target], splitting into parts when the plan
  /// asked for a multipart upload and finalising it afterwards.
  Future<UploadedAttachment> upload(
    Snowflake channelId,
    AttachmentUploadTarget target,
    Uint8List bytes, {
    String? title,
    String? description,
  }) async {
    switch (target) {
      case AttachmentUploadSinglepart(:final uploadUrl):
        await _uploader.put(uploadUrl, bytes, target.contentType);
      case AttachmentUploadMultipart(:final parts, :final partSize):
        for (final part in parts) {
          final start = (part.partNumber - 1) * partSize;
          if (start >= bytes.length) break;
          final end = start + partSize;
          await _uploader.put(
            part.uploadUrl,
            Uint8List.sublistView(
              bytes,
              start,
              end > bytes.length ? bytes.length : end,
            ),
            target.contentType,
          );
        }
        await complete(channelId, [target]);
    }
    return UploadedAttachment.of(
      target,
      title: title,
      description: description,
    );
  }

  /// Finalises multipart uploads so storage assembles their parts.
  ///
  /// [upload] already does this for a multipart target; call it directly
  /// only when driving the parts yourself.
  Future<void> complete(
    Snowflake channelId,
    List<AttachmentUploadMultipart> uploads,
  ) => _client.requestJson(
    method: 'POST',
    path: '/channels/$channelId/attachments/complete',
    bucketKey: 'POST /channels/:id/attachments/complete',
    body: {
      'uploads': uploads
          .map(
            (u) => {
              'upload_filename': u.uploadFilename,
              'upload_id': u.uploadId,
            },
          )
          .toList(growable: false),
    },
  );

  /// Plans and transfers one file, returning the claim to put on a
  /// message.
  ///
  /// [contentType] must match what is actually sent; storage rejects a
  /// mismatch.
  Future<UploadedAttachment> uploadFile(
    Snowflake channelId, {
    required String filename,
    required Uint8List bytes,
    required String contentType,
    String? title,
    String? description,
  }) async {
    final targets = await plan(channelId, [
      AttachmentUploadRequest(
        id: 0,
        filename: filename,
        fileSize: bytes.length,
        contentType: contentType,
      ),
    ]);
    return upload(
      channelId,
      targets.single,
      bytes,
      title: title,
      description: description,
    );
  }

  /// Removes an attachment from an existing message.
  Future<void> deleteFromMessage(
    Snowflake channelId,
    Snowflake messageId,
    Snowflake attachmentId,
  ) => _client.requestJson(
    method: 'DELETE',
    path: '/channels/$channelId/messages/$messageId/attachments/$attachmentId',
    bucketKey: 'DELETE /channels/:id/messages/:id/attachments/:id',
  );
}
