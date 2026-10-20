import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// What a message has to contain, for [MessageSearchBuilder.has].
enum MessageContentKind {
  image,
  sound,
  video,
  file,
  sticker,
  embed,
  link,
  poll,
  snapshot,
}

/// Who wrote a message, for [MessageSearchBuilder.authorTypes].
enum MessageAuthorKind { user, bot, webhook }

/// Builds the JSON body for `POST /search/messages`. Only the filters set
/// are sent.
///
/// A search must name where it runs: [inGuild] or [inChannel]. The
/// server rejects one without either, although the schema marks neither
/// as required.
final class MessageSearchBuilder {
  final _body = <String, dynamic>{};

  /// Searches the whole guild.
  MessageSearchBuilder inGuild(Snowflake guildId) {
    _body['context_guild_id'] = guildId.toJson();
    _body['scope'] = 'current';
    return this;
  }

  /// Searches one channel.
  MessageSearchBuilder inChannel(Snowflake channelId) {
    _body['context_channel_id'] = channelId.toJson();
    _body['scope'] = 'current';
    return this;
  }

  /// Full-text query.
  MessageSearchBuilder content(String content) {
    _body['content'] = content;
    return this;
  }

  /// Phrases that must appear verbatim, at most 10.
  MessageSearchBuilder exactPhrases(List<String> phrases) {
    _body['exact_phrases'] = phrases;
    return this;
  }

  /// Narrows a guild search to these channels, at most 500.
  MessageSearchBuilder channels(List<Snowflake> channelIds) {
    _body['channel_id'] = _ids(channelIds);
    return this;
  }

  MessageSearchBuilder authors(List<Snowflake> userIds) {
    _body['author_id'] = _ids(userIds);
    return this;
  }

  MessageSearchBuilder excludeAuthors(List<Snowflake> userIds) {
    _body['exclude_author_id'] = _ids(userIds);
    return this;
  }

  MessageSearchBuilder authorTypes(List<MessageAuthorKind> types) {
    _body['author_type'] = [for (final t in types) t.name];
    return this;
  }

  MessageSearchBuilder mentions(List<Snowflake> userIds) {
    _body['mentions'] = _ids(userIds);
    return this;
  }

  MessageSearchBuilder has(List<MessageContentKind> kinds) {
    _body['has'] = [for (final k in kinds) k.name];
    return this;
  }

  MessageSearchBuilder pinned([bool pinned = true]) {
    _body['pinned'] = pinned;
    return this;
  }

  /// Only messages newer than [after] and older than [before].
  MessageSearchBuilder between({Snowflake? after, Snowflake? before}) {
    if (after != null) _body['min_id'] = after.toJson();
    if (before != null) _body['max_id'] = before.toJson();
    return this;
  }

  MessageSearchBuilder includeNsfw([bool include = true]) {
    _body['include_nsfw'] = include;
    return this;
  }

  /// By relevance rather than newest first.
  MessageSearchBuilder sortByRelevance() {
    _body['sort_by'] = 'relevance';
    return this;
  }

  MessageSearchBuilder oldestFirst() {
    _body['sort_order'] = 'asc';
    return this;
  }

  /// [page] is 1-based, up to 400; [hitsPerPage] at most 25.
  MessageSearchBuilder page(int page, {int? hitsPerPage}) {
    _body['page'] = page;
    if (hitsPerPage != null) _body['hits_per_page'] = hitsPerPage;
    return this;
  }

  /// Continues from [MessageSearchResults.cursor].
  MessageSearchBuilder cursor(List<String> cursor) {
    _body['cursor'] = cursor;
    return this;
  }

  Map<String, dynamic> toJson() => Map.of(_body);

  static List<String> _ids(List<Snowflake> ids) => [
    for (final id in ids) id.toJson(),
  ];
}
