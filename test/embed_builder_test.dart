import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:test/test.dart';

void main() {
  group('EmbedBuilder', () {
    test('build() with nothing set produces an all-null embed', () {
      final embed = EmbedBuilder().build();

      expect(embed.title, isNull);
      expect(embed.fields, isEmpty);
    });

    test('chains every simple field', () {
      final embed = EmbedBuilder()
          .title('Title')
          .description('Description')
          .url('https://example.com')
          .color(0x4641d9)
          .build();

      expect(embed.title, 'Title');
      expect(embed.description, 'Description');
      expect(embed.url, 'https://example.com');
      expect(embed.color, 0x4641d9);
    });

    test('author()/footer()/image()/thumbnail() build the nested objects', () {
      final embed = EmbedBuilder()
          .author('Author', url: 'https://a.example.com')
          .footer('Footer')
          .image('https://img.example.com')
          .thumbnail('https://thumb.example.com')
          .build();

      expect(embed.author?.name, 'Author');
      expect(embed.author?.url, 'https://a.example.com');
      expect(embed.footer?.text, 'Footer');
      expect(embed.image?.url, 'https://img.example.com');
      expect(embed.thumbnail?.url, 'https://thumb.example.com');
    });

    test('field() is additive and preserves call order', () {
      final embed = EmbedBuilder()
          .field('f1', 'v1')
          .field('f2', 'v2', inline: true)
          .build();

      expect(embed.fields, hasLength(2));
      expect(embed.fields[0].name, 'f1');
      expect(embed.fields[0].inline, isFalse);
      expect(embed.fields[1].inline, isTrue);
    });

    test('timestamp() defaults to now when called with no argument', () {
      final before = DateTime.now();
      final embed = EmbedBuilder().timestamp().build();
      final after = DateTime.now();

      expect(
        embed.timestamp!.isAfter(before) || embed.timestamp == before,
        isTrue,
      );
      expect(
        embed.timestamp!.isBefore(after) || embed.timestamp == after,
        isTrue,
      );
    });

    test('timestamp() uses the given value when passed one', () {
      final ts = DateTime.utc(2026);
      final embed = EmbedBuilder().timestamp(ts).build();

      expect(embed.timestamp, ts);
    });
  });
}
