import 'package:fluxer_dart_core/fluxer_dart_core.dart';

/// Builds an [Embed]. Fluent/chainable (Builder pattern), matching
/// [MessageBuilder]'s own shape — this is the Dart-idiomatic way to
/// construct a deeply nested request object one decision at a time, not
/// a port of any particular other ecosystem's embed builder.
final class EmbedBuilder {
  String? _title;
  String? _description;
  String? _url;
  int? _color;
  DateTime? _timestamp;
  EmbedAuthor? _author;
  EmbedFooter? _footer;
  EmbedMedia? _image;
  EmbedMedia? _thumbnail;
  final _fields = <EmbedField>[];

  EmbedBuilder title(String title) {
    _title = title;
    return this;
  }

  EmbedBuilder description(String description) {
    _description = description;
    return this;
  }

  EmbedBuilder url(String url) {
    _url = url;
    return this;
  }

  /// RGB, packed as `0xRRGGBB`.
  EmbedBuilder color(int color) {
    _color = color;
    return this;
  }

  EmbedBuilder timestamp([DateTime? timestamp]) {
    _timestamp = timestamp ?? DateTime.now();
    return this;
  }

  EmbedBuilder author(String name, {String? url, String? iconUrl}) {
    _author = EmbedAuthor(name: name, url: url, iconUrl: iconUrl);
    return this;
  }

  EmbedBuilder footer(String text, {String? iconUrl}) {
    _footer = EmbedFooter(text: text, iconUrl: iconUrl);
    return this;
  }

  EmbedBuilder image(String url) {
    _image = EmbedMedia(url: url);
    return this;
  }

  EmbedBuilder thumbnail(String url) {
    _thumbnail = EmbedMedia(url: url);
    return this;
  }

  EmbedBuilder field(String name, String value, {bool inline = false}) {
    _fields.add(EmbedField(name: name, value: value, inline: inline));
    return this;
  }

  Embed build() => Embed(
    title: _title,
    description: _description,
    url: _url,
    color: _color,
    timestamp: _timestamp,
    author: _author,
    footer: _footer,
    image: _image,
    thumbnail: _thumbnail,
    fields: List.unmodifiable(_fields),
  );
}
