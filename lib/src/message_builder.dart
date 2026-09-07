import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds the JSON body for an outgoing message. Fluent/chainable
/// (Builder pattern) so call sites read as a sequence of decisions rather
/// than one large positional-argument constructor call.
final class MessageBuilder {
  // Can't use an initializing formal here: the public param name (content)
  // intentionally differs from the private field it seeds, and a private
  // named parameter wouldn't be callable from outside this library.
  // ignore: prefer_initializing_formals
  MessageBuilder({String? content}) : _content = content;

  String? _content;
  final _embeds = <Embed>[];
  final _stickerIds = <Snowflake>[];
  final _attachments = <UploadedAttachment>[];
  MessageReference? _messageReference;
  AllowedMentions? _allowedMentions;
  MessageFlags _flags = MessageFlags.none;
  String? _nonce;
  bool _tts = false;

  MessageBuilder content(String content) {
    _content = content;
    return this;
  }

  /// Adds [embed] to this message. Callable more than once — Fluxer
  /// allows multiple embeds per message.
  MessageBuilder embed(Embed embed) {
    _embeds.add(embed);
    return this;
  }

  /// Makes this message a reply to [messageId], in the same channel it's
  /// sent to.
  MessageBuilder replyTo(Snowflake messageId) {
    _messageReference = MessageReference(messageId: messageId);
    return this;
  }

  /// Restricts which mentions in this message notify anyone.
  ///
  /// Without it, every mention the content parses to notifies its target.
  /// [AllowedMentions.none] is the safe choice when the content came from
  /// a user, which otherwise lets a caller make the bot ping everyone.
  MessageBuilder allowedMentions(AllowedMentions mentions) {
    _allowedMentions = mentions;
    return this;
  }

  /// Sets a behaviour flag. Callable more than once; flags accumulate.
  MessageBuilder flag(MessageFlag flag) {
    _flags = _flags | flag;
    return this;
  }

  /// Attaches a sticker. Callable up to three times.
  MessageBuilder sticker(Snowflake stickerId) {
    _stickerIds.add(stickerId);
    return this;
  }

  /// Claims a file already transferred through the upload flow.
  ///
  /// Callable more than once, up to ten attachments per message.
  MessageBuilder attachment(UploadedAttachment attachment) {
    _attachments.add(attachment);
    return this;
  }

  /// Requests text-to-speech playback. Forced back to false without
  /// `sendTtsMessages`.
  MessageBuilder tts([bool enabled = true]) {
    _tts = enabled;
    return this;
  }

  /// A client-generated identifier, 1-32 characters, echoed on the
  /// resulting message so a send can be matched to its response even if
  /// the reply is lost.
  MessageBuilder nonce(String nonce) {
    _nonce = nonce;
    return this;
  }

  Map<String, dynamic> toJson() {
    if (_content == null &&
        _embeds.isEmpty &&
        _stickerIds.isEmpty &&
        _attachments.isEmpty) {
      throw StateError(
        'MessageBuilder requires content, an embed, a sticker or an '
        'attachment to be set',
      );
    }
    return {
      if (_content != null) 'content': _content,
      if (_embeds.isNotEmpty)
        'embeds': _embeds.map((e) => e.toJson()).toList(growable: false),
      if (_attachments.isNotEmpty)
        'attachments': _attachments
            .map((a) => a.toJson())
            .toList(growable: false),
      if (_stickerIds.isNotEmpty)
        'sticker_ids': _stickerIds
            .map((s) => s.toJson())
            .toList(growable: false),
      if (_messageReference != null)
        'message_reference': _messageReference!.toJson(),
      if (_allowedMentions != null)
        'allowed_mentions': _allowedMentions!.toJson(),
      if (_flags != MessageFlags.none) 'flags': _flags.value,
      if (_tts) 'tts': true,
      if (_nonce != null) 'nonce': _nonce,
    };
  }
}
