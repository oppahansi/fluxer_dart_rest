import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds the JSON body for `POST /guilds/{id}/channels`. Fluent/chainable
/// (Builder pattern), matching this package's other builders. Only the
/// fields set are sent.
///
/// Giving a [parent] moves the permission check into that category: the
/// caller needs `manageChannels` there, and `manageRoles` there as well
/// when [permissionOverwrite] is used. A category overwrite can grant or
/// deny either one regardless of the guild-level permission.
final class ChannelCreateBuilder {
  ChannelCreateBuilder({required String name, required ChannelType type})
    : _body = {'name': name, 'type': type.value};

  final Map<String, dynamic> _body;
  final _overwrites = <Map<String, dynamic>>[];

  ChannelCreateBuilder topic(String topic) {
    _body['topic'] = topic;
    return this;
  }

  /// The category to create the channel in.
  ChannelCreateBuilder parent(Snowflake categoryId) {
    _body['parent_id'] = categoryId.toJson();
    return this;
  }

  ChannelCreateBuilder nsfw([bool nsfw = true]) {
    _body['nsfw'] = nsfw;
    return this;
  }

  /// Slowmode, in seconds between messages per user (0-21600).
  ChannelCreateBuilder rateLimitPerUser(int seconds) {
    _body['rate_limit_per_user'] = seconds;
    return this;
  }

  /// Voice bitrate in bits per second (8000-384000).
  ChannelCreateBuilder bitrate(int bitsPerSecond) {
    _body['bitrate'] = bitsPerSecond;
    return this;
  }

  /// Voice user limit, 0 for none (0-99).
  ChannelCreateBuilder userLimit(int limit) {
    _body['user_limit'] = limit;
    return this;
  }

  /// Adds an overwrite for the role or member [targetId].
  ChannelCreateBuilder permissionOverwrite(
    Snowflake targetId,
    PermissionOverwrite overwrite,
  ) {
    _overwrites.add({'id': targetId.toJson(), ...overwrite.toJson()});
    return this;
  }

  /// Raw [ChannelFlag] bitfield.
  ChannelCreateBuilder flags(int flags) {
    _body['flags'] = flags;
    return this;
  }

  /// Forum and media channels: the archive duration new posts inherit.
  ChannelCreateBuilder defaultAutoArchiveDuration(
    ThreadAutoArchiveDuration duration,
  ) {
    _body['default_auto_archive_duration'] = duration.minutes;
    return this;
  }

  /// Forum and media channels: the slowmode new posts inherit.
  ChannelCreateBuilder defaultThreadRateLimitPerUser(int seconds) {
    _body['default_thread_rate_limit_per_user'] = seconds;
    return this;
  }

  ChannelCreateBuilder defaultReaction(ForumDefaultReaction reaction) {
    _body['default_reaction_emoji'] = reaction.toJson();
    return this;
  }

  ChannelCreateBuilder defaultSortOrder(ForumSortOrder order) {
    _body['default_sort_order'] = order.value;
    return this;
  }

  ChannelCreateBuilder defaultLayout(ForumLayout layout) {
    _body['default_forum_layout'] = layout.value;
    return this;
  }

  ChannelCreateBuilder defaultTagSetting(ForumTagSetting setting) {
    _body['default_tag_setting'] = setting.value;
    return this;
  }

  Map<String, dynamic> toJson() => {
    ..._body,
    if (_overwrites.isNotEmpty) 'permission_overwrites': List.of(_overwrites),
  };
}
