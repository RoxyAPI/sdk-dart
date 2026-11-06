import 'package:roxyapi/roxyapi.dart';
import 'package:roxyapi/src/json.dart';
import 'package:test/test.dart';

import '../tool/spec.dart';
import 'spec_fixture.dart';

/// The 200 schema of [operationId], references resolved.
Json responseSchema(String operationId) {
  final op = committedApi.operations.firstWhere(
    (o) => o.operationId == operationId,
  );
  final get = asJson(
    asJson(committedApi.spec['paths'], 'paths')[op.path],
    op.path,
  )[op.verb];
  final ok = asJson(
    asJson(asJson(get, op.verb)['responses'], 'responses')['200'],
    '200',
  );
  final media = asJson(
    asJson(ok['content'], 'content')['application/json'],
    'json',
  );
  return resolve(asJson(media['schema'], 'schema'));
}

Json resolve(Json schema) {
  final ref = asText(schema[r'$ref']);
  if (ref == null) return schema;
  final schemas = asJson(
    asJson(committedApi.spec['components'], 'c')['schemas'],
    's',
  );
  return resolve(asJson(schemas[ref.split('/').last], ref));
}

/// A JSON value built from the `example` of every property of [schema].
Object? example(Json schema) {
  final s = resolve(schema);
  if (s['example'] != null) return s['example'];
  final props = s['properties'];
  if (props is Map<String, Object?>) {
    return {
      for (final MapEntry(:key, :value) in props.entries)
        key: example(asJson(value, key)),
    };
  }
  final items = s['items'];
  if (items is Map<String, Object?>) return [example(items)];
  return null;
}

Json property(Json schema, String name) =>
    resolve(asJson(asJson(schema['properties'], 'properties')[name], name));

void main() {
  test('a nullable field reads null as null and a value as its type', () {
    final schema = responseSchema('analyzeNumberSequence');
    expect(property(schema, 'knownMeaning')['type'], ['object', 'null']);
    final body = asJson(example(schema), 'example');
    final meaning = asJson(body['knownMeaning'], 'knownMeaning');

    final uncurated = AnalyzeNumberSequenceResponse.fromJson({
      ...body,
      'knownMeaning': null,
    });
    expect(uncurated.knownMeaning, isNull);
    final curated = AnalyzeNumberSequenceResponse.fromJson(body);
    expect(curated.knownMeaning?.json, meaning);
    expect(curated.number, body['number']);
    expect(curated.isRepeating, body['isRepeating']);
  });

  test(
    'NumOrString reads both branches, with the timezone examples of the spec',
    () {
      final request = resolve({
        r'$ref': '#/components/schemas/NatalChartRequest',
      });
      final timezone = property(request, 'timezone');
      final branches = asJsonList(
        timezone['oneOf'] ?? timezone['anyOf'],
        'timezone',
      );
      expect(
        [for (final b in branches) asJson(b, 'branch')['type']],
        ['number', 'string'],
      );

      final number = asNumOrString(5.5, 'timezone');
      expect(number.asNum, 5.5);
      expect(number.asString, isNull);
      final name = asNumOrString('Europe/London', 'timezone');
      expect(name.asString, 'Europe/London');
      expect(name.asNum, isNull);
      expect(() => asNumOrString(true, 'timezone'), throwsFormatException);
    },
  );

  test('an open map decodes each value and stays read-only', () {
    final schema = responseSchema('analyzeKarmicLessons');
    expect(
      property(schema, 'presentNumbers')['additionalProperties'],
      isA<Map<String, Object?>>(),
    );
    final body = asJson(example(schema), 'example');
    final lessons = AnalyzeKarmicLessonsResponse.fromJson({
      ...body,
      'presentNumbers': {'1': 2, '5': 1.0},
    });
    expect(lessons.presentNumbers, {'1': 2, '5': 1.0});
    expect(lessons.presentNumbers['9'], isNull);
    expect(() => lessons.presentNumbers['1'] = 3, throwsUnsupportedError);
  });

  test('a map of lists decodes through both levels', () {
    final schema = responseSchema('calculateBhavChalit');
    final body = asJson(example(schema), 'example');
    final chart = BhavChalitResponse.fromJson({
      ...body,
      'houseThemes': {
        '1': ['self', 'body'],
      },
    });
    expect(chart.houseThemes['1'], ['self', 'body']);
  });

  test('a nested list reads each element as its model', () {
    final schema = responseSchema('searchCities');
    final body = asJson(example(schema), 'example');
    final city = asJson(asJsonList(body['cities'], 'cities').single, 'city');
    final result = SearchCitiesResponse.fromJson({
      ...body,
      'cities': [city, city],
    });
    expect(result.cities, hasLength(2));
    expect(result.cities.first.city, city['city']);
    expect(result.cities.last.latitude, city['latitude']);
    expect(result.cities.map((c) => c.timezone).toSet(), {city['timezone']});
    expect(
      () => result.cities.add(result.cities.first),
      throwsUnsupportedError,
    );
  });

  test('a wrong-typed field throws FormatException naming the field', () {
    final schema = responseSchema('searchCities');
    final body = asJson(example(schema), 'example');
    final city = asJson(asJsonList(body['cities'], 'cities').single, 'city');

    final badLatitude = SearchCitiesResponse.fromJson({
      ...body,
      'cities': [
        {...city, 'latitude': '51.5'},
      ],
    });
    expect(
      () => badLatitude.cities.first.latitude,
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('"latitude"'),
        ),
      ),
    );

    final badElement = SearchCitiesResponse.fromJson({
      ...body,
      'cities': [city, 'Paris'],
    });
    expect(
      () => badElement.cities[1],
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('"cities[1]"'),
        ),
      ),
    );

    final missing = SearchCitiesResponse.fromJson(<String, Object?>{});
    expect(() => missing.cities, throwsFormatException);
  });

  test(
    'numbers are tolerant of integral JSON and strict about everything else',
    () {
      expect(asInt(3.0, 'n'), 3);
      expect(() => asInt(3.5, 'n'), throwsFormatException);
      expect(asNum(3, 'n'), same(3));
      expect(() => asNum('3', 'n'), throwsFormatException);
      expect(() => asBool('true', 'b'), throwsFormatException);
    },
  );

  test('an unknown field is ignored and kept in json', () {
    final schema = responseSchema('searchCities');
    final body = {...asJson(example(schema), 'example'), 'addedLater': 1};
    final result = SearchCitiesResponse.fromJson(body);
    expect(result.json['addedLater'], 1);
    expect(result.cities, isNotEmpty);
  });
}
