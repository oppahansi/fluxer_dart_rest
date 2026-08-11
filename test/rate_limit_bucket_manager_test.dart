import 'package:fluxer_rest/fluxer_rest.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimitBucketManager', () {
    test('an unseen route has no wait time', () {
      final manager = RateLimitBucketManager();
      expect(manager.waitTimeFor('GET /guilds/:id'), Duration.zero);
    });

    test('ignores headers when any of the three are missing', () {
      final manager = RateLimitBucketManager();
      manager.updateFromHeaders('GET /x', {'x-ratelimit-limit': '5'});
      expect(manager.waitTimeFor('GET /x'), Duration.zero);
    });

    test(
      'learns a bucket from response headers and reflects remaining headroom',
      () {
        final manager = RateLimitBucketManager();
        final resetAt = DateTime.now().toUtc().add(const Duration(seconds: 10));
        manager.updateFromHeaders('GET /x', {
          'x-ratelimit-limit': '5',
          'x-ratelimit-remaining': '5',
          'x-ratelimit-reset': (resetAt.millisecondsSinceEpoch / 1000)
              .toString(),
        });

        expect(manager.waitTimeFor('GET /x'), Duration.zero);
      },
    );

    test('waitTimeFor is positive once the bucket is exhausted', () {
      final manager = RateLimitBucketManager();
      final resetAt = DateTime.now().toUtc().add(const Duration(seconds: 10));
      manager.updateFromHeaders('GET /x', {
        'x-ratelimit-limit': '1',
        'x-ratelimit-remaining': '1',
        'x-ratelimit-reset': (resetAt.millisecondsSinceEpoch / 1000).toString(),
      });

      manager.consume('GET /x');
      expect(manager.waitTimeFor('GET /x'), greaterThan(Duration.zero));
    });
  });
}
