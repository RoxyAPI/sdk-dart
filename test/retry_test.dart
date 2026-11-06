@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roxyapi/roxyapi.dart';
import 'package:roxyapi/src/transport.dart';
import 'package:test/test.dart';

/// One scripted reply: a status and its headers, or an error the transport throws.
final class Step {
  Step(this.status, [this.headers = const {}]) : error = null;
  Step.fail(Object this.error) : status = 0, headers = const {};
  final int status;
  final Map<String, String> headers;
  final Object? error;
  bool cancelled = false;
}

/// A transport over scripted replies, a recording sleep and a fixed random.
final class Harness {
  Harness(
    this.steps, {
    int maxRetries = 2,
    Duration maxDelay = const Duration(seconds: 30),
    Duration? timeout,
    double random = 0.5,
  }) {
    transport = Transport(
      apiKey: 'k',
      baseUrl: Uri.parse('https://roxyapi.com/api/v2'),
      maxRetries: maxRetries,
      maxDelay: maxDelay,
      timeout: timeout,
      random: () => random,
      now: () => DateTime.utc(2026),
      sleep: (delay) async => sleeps.add(delay.inMicroseconds / 1000),
      client: MockClient.streaming((request, body) async {
        bodies.add(utf8.decode(await body.toBytes()));
        if (steps.isEmpty) throw StateError('transport exhausted');
        final step = steps.removeAt(0);
        sent.add(step);
        final error = step.error;
        if (error != null) throw error;
        final payload = utf8.encode(
          jsonEncode({'error': 'e', 'code': 'c${step.status}'}),
        );
        final controller = StreamController<List<int>>(
          onCancel: () => step.cancelled = true,
        )..add(payload);
        unawaited(controller.close());
        return http.StreamedResponse(
          controller.stream,
          step.status,
          headers: step.headers,
        );
      }),
    );
  }

  final List<Step> steps;
  final List<Step> sent = [];
  final List<double> sleeps = [];
  final List<String> bodies = [];
  late final Transport transport;

  Future<Object?> post() => transport.send('POST', '/x', body: {'a': 1});
}

Matcher roxyError(int status, {Duration? retryAfter}) => isA<RoxyException>()
    .having((e) => e.statusCode, 'statusCode', status)
    .having((e) => e.retryAfter, 'retryAfter', retryAfter);

SocketException refused() => const SocketException(
  'Connection refused',
  osError: OSError('Connection refused', 111),
);

void main() {
  group('retries', () {
    test(
      'retries a 429 rate_limit_per_minute once with Retry-After, then succeeds',
      () async {
        final h = Harness([
          Step(429, {'retry-after': '1'}),
          Step(200),
        ]);
        await h.post();
        expect(h.sent, hasLength(2));
        expect(h.sleeps, [1000 + 0.5 * 500]);
        expect(h.bodies, ['{"a":1}', '{"a":1}']);
      },
    );

    test(
      'does not retry rate_limit_exceeded when Retry-After exceeds the max delay',
      () async {
        final h = Harness([
          Step(429, {'retry-after': '86400'}),
        ], maxRetries: 3);
        await expectLater(
          h.post(),
          throwsA(roxyError(429, retryAfter: const Duration(seconds: 86400))),
        );
        expect(h.sent, hasLength(1));
      },
    );

    test('retries a 503 compute_saturated with full jitter backoff', () async {
      final h = Harness(
        [Step(503), Step(503), Step(200)],
        maxRetries: 3,
        random: 1,
      );
      await h.post();
      expect(h.sleeps, [500, 1000]);
    });

    test('keeps jitter inside [0, min(max, initial * 2^attempt)]', () async {
      final h = Harness(
        [Step(502), Step(200)],
        maxRetries: 1,
        maxDelay: const Duration(milliseconds: 800),
        random: 0.999,
      );
      await h.post();
      expect(h.sleeps.single, inInclusiveRange(0, 500));
    });

    test('retries a 500', () async {
      final h = Harness([Step(500), Step(200)], maxRetries: 3);
      await h.post();
      expect(h.sent, hasLength(2));
    });

    test('never retries a 501 or a 4xx other than 429', () async {
      for (final status in [400, 401, 501]) {
        final h = Harness([Step(status)], maxRetries: 3);
        await expectLater(h.post(), throwsA(roxyError(status)));
        expect(h.sent, hasLength(1));
      }
    });

    test('retries a refused connection but not other network errors', () async {
      final ok = Harness([Step.fail(refused()), Step(200)], maxRetries: 1);
      await ok.post();
      expect(ok.sent, hasLength(2));

      final lookup = Harness([
        Step.fail(const SocketException("Failed host lookup: 'x'")),
        Step(200),
      ], maxRetries: 1);
      await lookup.post();
      expect(lookup.sent, hasLength(2));

      const reset = SocketException(
        'Connection reset',
        osError: OSError('reset', 104),
      );
      final bad = Harness([Step.fail(reset)], maxRetries: 3);
      await expectLater(bad.post(), throwsA(same(reset)));
      expect(bad.sent, hasLength(1));
    });

    test('stops after maxRetries and throws the last response', () async {
      final h = Harness([Step(503), Step(503)], maxRetries: 1);
      await expectLater(h.post(), throwsA(roxyError(503)));
      expect(h.sent, hasLength(2));
    });

    test(
      'throws the response when the timeout leaves no room for the wait',
      () async {
        final h = Harness(
          [
            Step(503, {'retry-after': '1'}),
          ],
          maxRetries: 3,
          timeout: const Duration(milliseconds: 100),
        );
        await expectLater(
          h.post(),
          throwsA(roxyError(503, retryAfter: const Duration(seconds: 1))),
        );
        expect(h.sent, hasLength(1));
        expect(h.sleeps, isEmpty);
      },
    );

    test(
      'cancels a discarded response body, and reads a returned one',
      () async {
        final first = Step(503);
        final h = Harness([first, Step(200)], maxRetries: 1);
        await h.post();
        expect(first.cancelled, isTrue);

        final k = Harness([
          Step(429, {'retry-after': '86400'}),
        ], maxRetries: 1);
        await expectLater(
          k.post(),
          throwsA(isA<RoxyException>().having((e) => e.code, 'code', 'c429')),
        );
      },
    );

    test('reads Retry-After as seconds or an HTTP date', () {
      final now = DateTime.utc(2026);
      expect(retryAfter('7', now), const Duration(seconds: 7));
      expect(
        retryAfter('Thu, 01 Jan 2026 00:00:10 GMT', now),
        const Duration(seconds: 10),
      );
      expect(retryAfter('Wed, 31 Dec 2025 23:59:00 GMT', now), Duration.zero);
      expect(retryAfter('garbage', now), isNull);
      expect(retryAfter('-5', now), isNull);
      expect(retryAfter(null, now), isNull);
      expect(retryAfter('', now), isNull);
    });
  });

  group('Roxy retries', () {
    http.Client saturated(List<int> calls, {int okAfter = -1}) =>
        MockClient((request) async {
          calls.add(1);
          return calls.length == okAfter
              ? http.Response('{"sign":"aries"}', 200)
              : http.Response(
                  '{"error":"busy","code":"compute_saturated"}',
                  503,
                  headers: {'retry-after': '0'},
                );
        });

    const fast = Duration(milliseconds: 1);

    test('retries twice by default, then throws the error', () async {
      final calls = <int>[];
      final roxy = Roxy('k', client: saturated(calls), initialDelay: fast);
      await expectLater(
        roxy.astrology.getDailyHoroscope(sign: Sign.aries),
        throwsA(
          isA<RoxyException>().having(
            (e) => e.code,
            'code',
            ErrorCodes.computeSaturated,
          ),
        ),
      );
      expect(calls, hasLength(3));
    });

    test('never retries with maxRetries: 0', () async {
      final calls = <int>[];
      final roxy = Roxy('k', client: saturated(calls), maxRetries: 0);
      await expectLater(
        roxy.astrology.getDailyHoroscope(sign: Sign.aries),
        throwsA(isA<RoxyException>()),
      );
      expect(calls, hasLength(1));
    });

    test('retries through the client when maxRetries is set', () async {
      final calls = <int>[];
      final roxy = Roxy(
        'k',
        client: saturated(calls, okAfter: 2),
        maxRetries: 1,
        initialDelay: fast,
      );
      final horoscope = await roxy.astrology.getDailyHoroscope(
        sign: Sign.aries,
      );
      expect(calls, hasLength(2));
      expect(horoscope.sign, 'aries');
    });
  });
}
