import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds the JSON body for `POST /guilds/{id}/channels`. Fluent/chainable
/// (Builder pattern), matching this package's other builders.
final class ChannelCreateBuilder {
  // Can't use initializing formals here: the public param names (name,
  // type) intentionally differ from the private fields they seed, and
  // private named parameters wouldn't be callable from outside this
  // library.
  ChannelCreateBuilder({required String name, required ChannelType type})
    : _name = name, // ignore: prefer_initializing_formals
      _type = type; // ignore: prefer_initializing_formals

  final String _name;
  final ChannelType _type;
  String? _topic;

  ChannelCreateBuilder topic(String topic) {
    _topic = topic;
    return this;
  }

  Map<String, dynamic> toJson() => {
    'name': _name,
    'type': _type.value,
    if (_topic != null) 'topic': _topic,
  };
}
