import 'package:fluxer_dart_core/fluxer_dart_core.dart';

import 'rest_client.dart';

/// Guild discovery: browsing listed guilds, and a guild's own application
/// to be listed.
final class DiscoveryRestManager {
  const DiscoveryRestManager(this._client);

  final RestClient _client;

  Future<List<DiscoveryCategory>> categories() async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/discovery/categories',
      bucketKey: 'GET /discovery/categories',
    );
    return (json as List<dynamic>)
        .map((c) => DiscoveryCategory.fromJson(c as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Listed guilds matching [query]; [limit] is 1-48.
  Future<DiscoveryGuildPage> search({
    String? query,
    int? category,
    String? language,
    String? tag,
    String? sortBy,
    int limit = 24,
    int offset = 0,
  }) async {
    final params = [
      if (query != null) 'query=${Uri.encodeQueryComponent(query)}',
      if (category != null) 'category=$category',
      if (language != null) 'language=${Uri.encodeQueryComponent(language)}',
      if (tag != null) 'tag=${Uri.encodeQueryComponent(tag)}',
      if (sortBy != null) 'sort_by=$sortBy',
      'limit=$limit',
      'offset=$offset',
    ].join('&');
    final json = await _client.requestJson(
      method: 'GET',
      path: '/discovery/guilds?$params',
      bucketKey: 'GET /discovery/guilds',
    );
    return DiscoveryGuildPage.fromJson(json as Map<String, dynamic>);
  }

  Future<DiscoveryStatus> status(Snowflake guildId) async {
    final json = await _client.requestJson(
      method: 'GET',
      path: '/guilds/$guildId/discovery',
      bucketKey: 'GET /guilds/:id/discovery',
    );
    return DiscoveryStatus.fromJson(json as Map<String, dynamic>);
  }

  /// Applies to list [guildId]. [categoryType] is a
  /// [DiscoveryCategory.id]; the application starts out pending review.
  Future<DiscoveryApplication> apply(
    Snowflake guildId, {
    required String description,
    required int categoryType,
    String? primaryLanguage,
    List<String> customTags = const [],
  }) async {
    final json = await _client.requestJson(
      method: 'POST',
      path: '/guilds/$guildId/discovery',
      bucketKey: 'POST /guilds/:id/discovery',
      body: {
        'description': description,
        'category_type': categoryType,
        'primary_language': ?primaryLanguage,
        if (customTags.isNotEmpty) 'custom_tags': customTags,
      },
    );
    return DiscoveryApplication.fromJson(json as Map<String, dynamic>);
  }

  Future<DiscoveryApplication> edit(
    Snowflake guildId, {
    String? description,
    int? categoryType,
    String? primaryLanguage,
    List<String>? customTags,
  }) async {
    final json = await _client.requestJson(
      method: 'PATCH',
      path: '/guilds/$guildId/discovery',
      bucketKey: 'PATCH /guilds/:id/discovery',
      body: {
        'description': ?description,
        'category_type': ?categoryType,
        'primary_language': ?primaryLanguage,
        'custom_tags': ?customTags,
      },
    );
    return DiscoveryApplication.fromJson(json as Map<String, dynamic>);
  }

  /// Withdraws the application, or delists a listed guild.
  Future<void> withdraw(Snowflake guildId) => _client.requestJson(
    method: 'DELETE',
    path: '/guilds/$guildId/discovery',
    bucketKey: 'DELETE /guilds/:id/discovery',
  );
}
