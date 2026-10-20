import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds the JSON body for `PATCH /guilds/{id}/roles/{id}`. Only the
/// fields set are sent; the rest keep their current values.
final class GuildRoleUpdateBuilder {
  final _body = <String, dynamic>{};

  /// 1-100 characters.
  GuildRoleUpdateBuilder name(String name) {
    _body['name'] = name;
    return this;
  }

  /// An RGB colour as `0xRRGGBB`; `0` means no colour.
  GuildRoleUpdateBuilder color(int color) {
    _body['color'] = color;
    return this;
  }

  GuildRoleUpdateBuilder permissions(Permissions permissions) {
    _body['permissions'] = permissions.toJson();
    return this;
  }

  /// Whether members with this role are listed in their own group.
  GuildRoleUpdateBuilder hoist([bool hoist = true]) {
    _body['hoist'] = hoist;
    return this;
  }

  /// Whether anyone can mention this role.
  GuildRoleUpdateBuilder mentionable([bool mentionable = true]) {
    _body['mentionable'] = mentionable;
    return this;
  }

  Map<String, dynamic> toJson() => Map.of(_body);
}
