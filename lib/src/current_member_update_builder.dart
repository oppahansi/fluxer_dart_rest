/// Builds the JSON body for `PATCH /guilds/{id}/members/@me`: this bot's
/// own profile within one guild. Only the fields set are sent; passing
/// `null` to a setter clears that field back to the account-wide value.
final class CurrentMemberUpdateBuilder {
  final _body = <String, dynamic>{};

  /// 1-32 characters, or `null` to remove the nickname.
  CurrentMemberUpdateBuilder nick(String? nick) {
    _body['nick'] = nick;
    return this;
  }

  /// A data URI (`data:image/png;base64,...`), or `null` to remove the
  /// guild avatar.
  CurrentMemberUpdateBuilder avatar(String? dataUri) {
    _body['avatar'] = dataUri;
    return this;
  }

  /// A data URI, or `null` to remove the guild banner.
  CurrentMemberUpdateBuilder banner(String? dataUri) {
    _body['banner'] = dataUri;
    return this;
  }

  /// 1-320 characters, or `null` to remove it.
  CurrentMemberUpdateBuilder bio(String? bio) {
    _body['bio'] = bio;
    return this;
  }

  /// 1-40 characters, or `null` to remove them.
  CurrentMemberUpdateBuilder pronouns(String? pronouns) {
    _body['pronouns'] = pronouns;
    return this;
  }

  /// An RGB colour as `0xRRGGBB`, or `null` to remove it.
  CurrentMemberUpdateBuilder accentColor(int? color) {
    _body['accent_color'] = color;
    return this;
  }

  Map<String, dynamic> toJson() => Map.of(_body);
}
