import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:test/test.dart';

void main() {
  group('ChannelUpdateBuilder', () {
    test('toJson always includes type, even with nothing else set', () {
      final json = ChannelUpdateBuilder(ChannelType.guildText).toJson();

      expect(json, {'type': ChannelType.guildText.value});
    });

    test('name()/topic()/rateLimitPerUser() are additive and optional', () {
      final json = ChannelUpdateBuilder(
        ChannelType.guildText,
      ).name('renamed').topic('new topic').rateLimitPerUser(10).toJson();

      expect(json, {
        'type': ChannelType.guildText.value,
        'name': 'renamed',
        'topic': 'new topic',
        'rate_limit_per_user': 10,
      });
    });
  });
}
