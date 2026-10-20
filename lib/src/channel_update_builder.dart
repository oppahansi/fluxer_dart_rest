import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds the JSON body for `PATCH /channels/{id}`. Fluent/chainable
/// (Builder pattern), matching this package's other builders. Only the
/// fields set are sent.
///
/// Fluxer's channel update schema requires the channel type on every
/// request — it's the discriminant across a union of per-channel-type
/// update schemas. Pass the channel's *current* type (channels can't
/// change type), not the type you're changing it to.
final class ChannelUpdateBuilder {
  ChannelUpdateBuilder(ChannelType type) : _body = {'type': type.value};

  final Map<String, dynamic> _body;

  ChannelUpdateBuilder name(String name) {
    _body['name'] = name;
    return this;
  }

  ChannelUpdateBuilder topic(String topic) {
    _body['topic'] = topic;
    return this;
  }

  /// Slowmode, in seconds between messages per user.
  ChannelUpdateBuilder rateLimitPerUser(int seconds) {
    _body['rate_limit_per_user'] = seconds;
    return this;
  }

  /// Moves the channel into [categoryId], or out of its category when
  /// `null`.
  ChannelUpdateBuilder parent(Snowflake? categoryId) {
    _body['parent_id'] = categoryId?.toJson();
    return this;
  }

  ChannelUpdateBuilder nsfw([bool nsfw = true]) {
    _body['nsfw'] = nsfw;
    return this;
  }

  /// Voice bitrate in bits per second (8000-384000).
  ChannelUpdateBuilder bitrate(int bitsPerSecond) {
    _body['bitrate'] = bitsPerSecond;
    return this;
  }

  /// Voice user limit, 0 for none (0-99).
  ChannelUpdateBuilder userLimit(int limit) {
    _body['user_limit'] = limit;
    return this;
  }

  /// Replaces every overwrite on the channel with [overwrites], keyed by
  /// the role or member they apply to. To change a single one, use
  /// `ChannelRestManager.setPermissionOverwrite`.
  ChannelUpdateBuilder permissionOverwrites(
    Map<Snowflake, PermissionOverwrite> overwrites,
  ) {
    _body['permission_overwrites'] = [
      for (final MapEntry(:key, :value) in overwrites.entries)
        {'id': key.toJson(), ...value.toJson()},
    ];
    return this;
  }

  /// Raw [ChannelFlag] bitfield.
  ChannelUpdateBuilder flags(int flags) {
    _body['flags'] = flags;
    return this;
  }

  /// Forum and media channels: the archive duration new posts inherit.
  ChannelUpdateBuilder defaultAutoArchiveDuration(
    ThreadAutoArchiveDuration duration,
  ) {
    _body['default_auto_archive_duration'] = duration.minutes;
    return this;
  }

  /// Forum and media channels: the slowmode new posts inherit.
  ChannelUpdateBuilder defaultThreadRateLimitPerUser(int seconds) {
    _body['default_thread_rate_limit_per_user'] = seconds;
    return this;
  }

  /// `null` removes the default reaction.
  ChannelUpdateBuilder defaultReaction(ForumDefaultReaction? reaction) {
    _body['default_reaction_emoji'] = reaction?.toJson();
    return this;
  }

  ChannelUpdateBuilder defaultSortOrder(ForumSortOrder order) {
    _body['default_sort_order'] = order.value;
    return this;
  }

  ChannelUpdateBuilder defaultLayout(ForumLayout layout) {
    _body['default_forum_layout'] = layout.value;
    return this;
  }

  ChannelUpdateBuilder defaultTagSetting(ForumTagSetting setting) {
    _body['default_tag_setting'] = setting.value;
    return this;
  }

  Map<String, dynamic> toJson() => Map.of(_body);
}
