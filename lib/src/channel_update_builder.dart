import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds the JSON body for `PATCH /channels/{id}`. Fluent/chainable
/// (Builder pattern), matching this package's other builders.
///
/// Fluxer's channel update schema requires [type] on every request — it's
/// the discriminant across a union of per-channel-type update schemas.
/// Pass the channel's *current* type (channels can't change type), not
/// the type you're changing it to.
final class ChannelUpdateBuilder {
  ChannelUpdateBuilder(ChannelType type) : _type = type;

  final ChannelType _type;
  String? _name;
  String? _topic;
  int? _rateLimitPerUser;

  ChannelUpdateBuilder name(String name) {
    _name = name;
    return this;
  }

  ChannelUpdateBuilder topic(String topic) {
    _topic = topic;
    return this;
  }

  /// Slowmode, in seconds between messages per user.
  ChannelUpdateBuilder rateLimitPerUser(int seconds) {
    _rateLimitPerUser = seconds;
    return this;
  }

  Map<String, dynamic> toJson() => {
    'type': _type.value,
    if (_name != null) 'name': _name,
    if (_topic != null) 'topic': _topic,
    if (_rateLimitPerUser != null) 'rate_limit_per_user': _rateLimitPerUser,
  };
}
