import 'package:fluxer_rest/fluxer_rest.dart';
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

    test('throws if no content was set', () {
      expect(() => MessageBuilder().toJson(), throwsStateError);
    });
  });
}
