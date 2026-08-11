import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:test/test.dart';

void main() {
  group('ChannelCreateBuilder', () {
    test('toJson includes name and the channel type as its wire value', () {
      final json = ChannelCreateBuilder(
        name: 'general',
        type: ChannelType.guildText,
      ).toJson();

      expect(json, {'name': 'general', 'type': ChannelType.guildText.value});
    });

    test('topic() adds an optional topic', () {
      final json = ChannelCreateBuilder(
        name: 'general',
        type: ChannelType.guildText,
      ).topic('Chat about anything').toJson();

      expect(json['topic'], 'Chat about anything');
    });
  });
}
