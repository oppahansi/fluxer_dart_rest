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

  MessageBuilder content(String content) {
    _content = content;
    return this;
  }

  Map<String, dynamic> toJson() {
    if (_content == null) {
      throw StateError('MessageBuilder requires at least content() to be set');
    }
    return {'content': _content};
  }
}
