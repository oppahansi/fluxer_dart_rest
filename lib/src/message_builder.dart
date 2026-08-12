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
  MessageReference? _messageReference;

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

  Map<String, dynamic> toJson() {
    if (_content == null && _embeds.isEmpty) {
      throw StateError(
        'MessageBuilder requires at least content() or embed() to be set',
      );
    }
    return {
      if (_content != null) 'content': _content,
      if (_embeds.isNotEmpty)
        'embeds': _embeds.map((e) => e.toJson()).toList(growable: false),
      if (_messageReference != null)
        'message_reference': _messageReference!.toJson(),
    };
  }
}
