import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roxyapi/roxyapi.dart';
import 'package:roxyapi/src/version.dart';
import 'package:test/test.dart';

import 'spec_fixture.dart';

http.Response json(
  int status,
  Object body, [
  Map<String, String> headers = const {},
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...headers},
);

/// A client over a mock transport that records every request it is sent.
(Roxy, List<http.Request>) harness(http.Response Function(http.Request) reply) {
  final sent = <http.Request>[];
  final roxy = Roxy(
    'test-key',
    maxRetries: 0,
    client: MockClient((request) async {
      sent.add(request);
      return reply(request);
    }),
  );
  return (roxy, sent);
}

void main() {
  test(
    'calls the base URL of the spec with the key and the SDK header',
    () async {
      final (roxy, sent) = harness(
        (_) => json(200, {'sign': 'aries', 'overview': 'A day'}),
      );
      final horoscope = await roxy.astrology.getDailyHoroscope(
        sign: Sign.aries,
      );

      expect(horoscope.sign, 'aries');
      expect(horoscope.overview, 'A day');
      final request = sent.single;
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        '${committedApi.baseUrl}/astrology/horoscope/aries/daily',
      );
      expect(request.headers['X-API-Key'], 'test-key');
      expect(request.headers['X-SDK-Client'], 'roxy-sdk-dart/$version');
    },
  );

  test(
    'encodes query values, enum wire values and leaves unset ones out',
    () async {
      final (roxy, sent) = harness(
        (_) => json(200, {'cities': <Object?>[], 'total': 0}),
      );
      await roxy.location.searchCities(q: 'São Paulo', limit: 5);
      await roxy.astrology.getDailyHoroscope(
        sign: Sign.pisces,
        lang: Lang.zhHans,
      );

      expect(sent[0].url.queryParameters, {'q': 'São Paulo', 'limit': '5'});
      expect(sent[1].url.queryParameters, {'lang': 'zh-Hans'});
    },
  );

  test(
    'sends the body as JSON with enum wire values and both NumOrString forms',
    () async {
      final (roxy, sent) = harness((_) => json(200, <String, Object?>{}));
      await roxy.astrology.generateNatalChart(
        date: '1990-01-15',
        time: '14:30:00',
        latitude: 51.5074,
        longitude: -0.1278,
        timezone: const NumOrString.string('Europe/London'),
        houseSystem: HouseSystem.wholeSign,
      );
      await roxy.astrology.generateNatalChart(
        date: '1990-01-15',
        time: '14:30:00',
        latitude: 19,
        longitude: 72,
        timezone: const NumOrString.number(5.5),
      );

      expect(sent[0].method, 'POST');
      expect(sent[0].headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(sent[0].body), {
        'date': '1990-01-15',
        'time': '14:30:00',
        'latitude': 51.5074,
        'longitude': -0.1278,
        'timezone': 'Europe/London',
        'houseSystem': 'whole-sign',
      });
      expect(jsonDecode(sent[1].body), containsPair('timezone', 5.5));
      expect(jsonDecode(sent[1].body), isNot(contains('houseSystem')));
    },
  );

  test('sends a nested request object built from its constructor', () async {
    final (roxy, sent) = harness((_) => json(200, <String, Object?>{}));
    final person1 = CalculateSynastryRequestPerson1(
      date: '1990-01-15',
      time: '14:30:00',
      latitude: 40.7128,
      longitude: -74.006,
      timezone: const NumOrString.string('America/New_York'),
      nodeType: NodeType.true$,
    );
    final person2 = CalculateSynastryRequestPerson2(
      date: '1992-07-22',
      time: '09:00:00',
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: const NumOrString.number(0),
    );
    await roxy.astrology.calculateSynastry(person1: person1, person2: person2);

    final body = jsonDecode(sent.single.body);
    expect(body, {'person1': person1.json, 'person2': person2.json});
    expect(person1.json['nodeType'], 'true');
    expect(person2.json, isNot(contains('nodeType')));
  });

  test(
    'throws RoxyException with the code, doc URL and message on a 401',
    () async {
      final (roxy, _) = harness(
        (_) => json(401, {
          'error': 'Invalid API key',
          'code': 'invalid_api_key',
          'doc_url': 'https://roxyapi.com/docs/errors#invalid_api_key',
        }),
      );

      await expectLater(
        roxy.astrology.getDailyHoroscope(sign: Sign.aries),
        throwsA(
          isA<RoxyException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.code, 'code', ErrorCodes.invalidApiKey)
              .having((e) => e.message, 'message', 'Invalid API key')
              .having(
                (e) => e.docUrl,
                'docUrl',
                'https://roxyapi.com/docs/errors#invalid_api_key',
              )
              .having((e) => e.retryAfter, 'retryAfter', isNull),
        ),
      );
    },
  );

  group('validation issues', () {
    Map<String, Object?> invalid(Object? issues) => {
      'error': 'Validation failed',
      'code': 'validation_error',
      'doc_url': 'https://roxyapi.com/docs/errors#validation_error',
      'issues': ?issues,
    };

    Future<RoxyException> thrown(Map<String, Object?> body) async {
      final (roxy, _) = harness((_) => json(400, body));
      try {
        await roxy.location.searchCities(q: '');
      } on RoxyException catch (e) {
        return e;
      }
      throw StateError('no RoxyException');
    }

    test('are typed when present', () async {
      final e = await thrown(
        invalid([
          {
            'path': 'date',
            'message': 'Invalid ISO date',
            'code': 'invalid_string',
          },
          {
            'path': 'latitude',
            'message': 'Too big',
            'maximum': 90,
            'inclusive': true,
          },
        ]),
      );
      expect(e.issues, hasLength(2));
      expect(e.issues.first.path, 'date');
      expect(e.issues.first.message, 'Invalid ISO date');
      expect(e.issues.first.code, 'invalid_string');
      expect(e.issues.last.maximum?.asNum, 90);
      expect(e.issues.last.inclusive, isTrue);
    });

    test('are empty when the body has none', () async {
      expect((await thrown(invalid(null))).issues, isEmpty);
    });

    test(
      'are empty when issues is not a list, and a bad entry names its field',
      () async {
        expect((await thrown(invalid('date is wrong'))).issues, isEmpty);
        final e = await thrown(invalid(['date is wrong']));
        expect(e.issues, hasLength(1));
        expect(
          () => e.issues.first,
          throwsA(
            isA<FormatException>().having(
              (f) => f.message,
              'message',
              contains('issues[0]'),
            ),
          ),
        );
      },
    );
  });

  test(
    'reads an error with no JSON body as the status with the code error',
    () async {
      final (roxy, _) = harness(
        (_) => http.Response('Request Entity Too Large', 413),
      );

      await expectLater(
        roxy.location.searchCities(q: 'London'),
        throwsA(
          isA<RoxyException>()
              .having((e) => e.statusCode, 'statusCode', 413)
              .having((e) => e.code, 'code', 'error')
              .having((e) => e.body, 'body', isNull),
        ),
      );
    },
  );

  test(
    'passes an unknown future error code through as a plain string',
    () async {
      final (roxy, _) = harness(
        (_) => json(409, {'error': 'x', 'code': 'a_code_added_later'}),
      );

      await expectLater(
        roxy.location.searchCities(q: 'London'),
        throwsA(
          isA<RoxyException>().having(
            (e) => e.code,
            'code',
            'a_code_added_later',
          ),
        ),
      );
    },
  );

  test('close leaves a caller-supplied client open', () async {
    var closed = false;
    final client = _ClosingClient(() => closed = true);
    Roxy('k', client: client).close();
    expect(closed, isFalse);
  });

  test('rejects a negative maxRetries', () {
    expect(() => Roxy('k', maxRetries: -1), throwsArgumentError);
  });
}

final class _ClosingClient extends http.BaseClient {
  _ClosingClient(this._onClose);
  final void Function() _onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => _onClose();
}
