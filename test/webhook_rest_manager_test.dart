import 'package:fluxer_core/fluxer_core.dart';
import 'package:fluxer_rest/fluxer_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

const _sampleWebhookJson =
    '{"id": "1", "guild_id": "2", "channel_id": "3", "name": "CI Bot", "avatar": null, '
    '"token": "secret", "user": {"id": "4", "username": "oppa", "discriminator": "0", '
    '"global_name": null, "avatar": null, "avatar_color": null, "bot": false, "system": false}}';

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  group('WebhookRestManager', () {
    late MockHttpTransport transport;
    late WebhookRestManager manager;

    setUp(() {
      transport = MockHttpTransport();
      manager = WebhookRestManager(
        RestClient(token: 't', transport: transport),
      );
    });

    test('listForChannel decodes an array of webhooks', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: '[$_sampleWebhookJson]',
        ),
      );

      final webhooks = await manager.listForChannel(Snowflake.parse('3'));

      expect(webhooks, hasLength(1));
      expect(webhooks.single.name, 'CI Bot');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.path, '/channels/3/webhooks');
    });

    test('get fetches a single webhook', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: _sampleWebhookJson,
        ),
      );

      final webhook = await manager.get(Snowflake.parse('1'));

      expect(webhook.token, 'secret');
    });

    test('createForChannel posts the name and decodes the response', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async => HttpTransportResponse(
          statusCode: 200,
          headers: const {},
          body: _sampleWebhookJson,
        ),
      );

      final webhook = await manager.createForChannel(
        Snowflake.parse('3'),
        name: 'CI Bot',
      );

      expect(webhook.name, 'CI Bot');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'POST');
      expect(captured.body, {'name': 'CI Bot'});
    });

    test('delete sends a DELETE', () async {
      when(() => transport.send(any())).thenAnswer(
        (_) async =>
            const HttpTransportResponse(statusCode: 204, headers: {}, body: ''),
      );

      await manager.delete(Snowflake.parse('1'));

      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.method, 'DELETE');
      expect(captured.path, '/webhooks/1');
    });
  });
}
