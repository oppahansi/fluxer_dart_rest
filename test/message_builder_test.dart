import 'package:fluxer_dart_core/fluxer_dart_core.dart';
import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:test/test.dart';

void main() {
  group('MessageBuilder', () {
    test('content() sets the content field', () {
      final json = MessageBuilder().content('hello').toJson();
      expect(json, {'content': 'hello'});
    });

    test('constructor content shorthand works without chaining', () {
      final json = MessageBuilder(content: 'hi').toJson();
      expect(json, {'content': 'hi'});
    });

    test('throws if neither content nor an embed was set', () {
      expect(() => MessageBuilder().toJson(), throwsStateError);
    });

    test('embed() alone satisfies the content-or-embed requirement', () {
      final embed = EmbedBuilder().title('Title').build();
      final json = MessageBuilder().embed(embed).toJson();

      expect(json, {
        'embeds': [
          {'title': 'Title'},
        ],
      });
      expect(json.containsKey('content'), isFalse);
    });

    test('embed() is additive — multiple calls add multiple embeds', () {
      final json = MessageBuilder(content: 'hi')
          .embed(EmbedBuilder().title('First').build())
          .embed(EmbedBuilder().title('Second').build())
          .toJson();

      expect(json['embeds'], [
        {'title': 'First'},
        {'title': 'Second'},
      ]);
    });

    test('replyTo() sets message_reference to the given message id', () {
      final json = MessageBuilder(
        content: 'hi',
      ).replyTo(const Snowflake(100)).toJson();

      expect(json['message_reference'], {'message_id': '100'});
    });
  });
}
