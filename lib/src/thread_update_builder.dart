import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds the JSON body for `PATCH /channels/{id}` on a thread.
/// Fluent/chainable (Builder pattern), matching this package's other
/// builders.
///
/// Unlike [ChannelUpdateBuilder], no channel type is sent: the API reads
/// the type from the thread itself.
///
/// An archived thread accepts no other change unless the same body also
/// calls [archived] with `false`.
final class ThreadUpdateBuilder {
  String? _name;
  bool? _archived;
  bool? _locked;
  bool? _invitable;
  ThreadAutoArchiveDuration? _autoArchiveDuration;
  int? _rateLimitPerUser;
  List<Snowflake>? _appliedTagIds;
  bool? _pinned;

  ThreadUpdateBuilder name(String name) {
    _name = name;
    return this;
  }

  /// Archives or unarchives the thread.
  ThreadUpdateBuilder archived([bool archived = true]) {
    _archived = archived;
    return this;
  }

  /// Locks or unlocks the thread. While locked, only thread moderators
  /// can act in it.
  ThreadUpdateBuilder locked([bool locked = true]) {
    _locked = locked;
    return this;
  }

  /// Whether a member who is not a thread moderator can add others.
  /// Private threads only.
  ThreadUpdateBuilder invitable([bool invitable = true]) {
    _invitable = invitable;
    return this;
  }

  /// Changing this resets the thread's archive timestamp.
  ThreadUpdateBuilder autoArchiveDuration(ThreadAutoArchiveDuration duration) {
    _autoArchiveDuration = duration;
    return this;
  }

  /// Slowmode, in seconds between messages per user (0-21600).
  ThreadUpdateBuilder rateLimitPerUser(int seconds) {
    _rateLimitPerUser = seconds;
    return this;
  }

  /// Replaces the complete set of tags on a forum or media post, at most
  /// five. Rejected on a public thread in a text channel.
  ThreadUpdateBuilder appliedTags(Iterable<Snowflake> tagIds) {
    _appliedTagIds = tagIds.toList(growable: false);
    return this;
  }

  /// Pins or unpins a forum or media post. A channel holds one pinned
  /// post at most.
  ThreadUpdateBuilder pinned([bool pinned = true]) {
    _pinned = pinned;
    return this;
  }

  Map<String, dynamic> toJson() => {
    'name': ?_name,
    'archived': ?_archived,
    'locked': ?_locked,
    'invitable': ?_invitable,
    'auto_archive_duration': ?_autoArchiveDuration?.minutes,
    'rate_limit_per_user': ?_rateLimitPerUser,
    if (_appliedTagIds != null)
      'applied_tags': _appliedTagIds!
          .map((t) => t.toJson())
          .toList(growable: false),
    if (_pinned != null) 'flags': _pinned! ? ChannelFlag.pinned.bit : 0,
  };
}
