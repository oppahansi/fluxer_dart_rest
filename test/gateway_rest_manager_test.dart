import 'package:fluxer_dart_rest/fluxer_dart_rest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpTransport extends Mock implements HttpTransport {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HttpTransportRequest(method: 'GET', path: '/'));
  });

  test(
    'GatewayRestManager.getBotGatewayInfo fetches and decodes gateway/bot',
    () async {
      final transport = MockHttpTransport();
      when(() => transport.send(any())).thenAnswer(
        (_) async => const HttpTransportResponse(
          statusCode: 200,
          headers: {},
          body:
              '{"url": "wss://gateway.fluxer.app", "shards": 1, '
              '"session_start_limit": {"total": 1000, "remaining": 999, "reset_after": 86400000, "max_concurrency": 1}}',
        ),
      );
      final manager = GatewayRestManager(
        RestClient(token: 't', transport: transport),
      );

      final info = await manager.getBotGatewayInfo();

      expect(info.url, 'wss://gateway.fluxer.app');
      final captured =
          verify(() => transport.send(captureAny())).captured.single
              as HttpTransportRequest;
      expect(captured.path, '/v1/gateway/bot');
    },
  );
}
