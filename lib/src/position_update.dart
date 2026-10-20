import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// One entry of a `PATCH /guilds/{id}/channels` reorder.
///
/// Either [position] or [precedingSiblingId] places the channel; the
/// latter names the channel it should directly follow. [parentId] moves
/// it into a category, and [moveToTopLevel] out of one.
final class ChannelPositionUpdate {
  const ChannelPositionUpdate(
    this.id, {
    this.position,
    this.parentId,
    this.moveToTopLevel = false,
    this.precedingSiblingId,
    this.lockPermissions,
  }) : assert(
         parentId == null || !moveToTopLevel,
         'parentId and moveToTopLevel are mutually exclusive',
       );

  final Snowflake id;
  final int? position;
  final Snowflake? parentId;
  final bool moveToTopLevel;
  final Snowflake? precedingSiblingId;

  /// Whether to replace the channel's overwrites with its new parent's.
  final bool? lockPermissions;

  Map<String, dynamic> toJson() => {
    'id': id.toJson(),
    'position': ?position,
    if (parentId != null) 'parent_id': parentId!.toJson(),
    if (moveToTopLevel) 'parent_id': null,
    if (precedingSiblingId != null)
      'preceding_sibling_id': precedingSiblingId!.toJson(),
    'lock_permissions': ?lockPermissions,
  };
}
