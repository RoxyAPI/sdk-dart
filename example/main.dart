// #docregion start
import 'dart:io';

import 'package:roxyapi/roxyapi.dart';
// #enddocregion start
import 'package:http/http.dart' as http;

// #docregion start

Future<void> main() async {
  final roxy = Roxy(Platform.environment['ROXY_API_KEY'] ?? '');

  final horoscope = await roxy.astrology.getDailyHoroscope(sign: Sign.aries);
  print('${horoscope.overview} Lucky number ${horoscope.luckyNumber}');
  // #enddocregion start

  // Every other call of the README, then the client is closed.
  try {
    await quickStart(roxy);
    await languages(roxy);
    await errors(roxy);
    await retries();
    await ownClient();
    await invalidKey();
  } finally {
    roxy.close();
  }
  // #docregion start
}
// #enddocregion start

Future<void> quickStart(Roxy roxy) async {
  // #docregion quick-start
  // Step 1: geocode the birth city once. Every chart endpoint takes these three values.
  final places = await roxy.location.searchCities(q: 'London');
  final place = places.cities.first;
  print('${place.city}, ${place.country}: ${place.timezone}');

  // Step 2: a Western natal chart. The timezone is the IANA name from the lookup; the server
  // resolves it to the DST-correct offset for the date of the chart.
  final chart = await roxy.astrology.generateNatalChart(
    date: '1990-01-15',
    time: '14:30:00',
    latitude: place.latitude,
    longitude: place.longitude,
    timezone: NumOrString.string(place.timezone),
  );
  // `planets` is a list: find a body by its `name`.
  final moon = chart.planets.firstWhere((p) => p.name == 'Moon');
  print('Moon in ${moon.sign}, ${chart.ascendant.sign} rising');

  // Step 3: the same birth as a Vedic kundli. Same inputs, sidereal zodiac.
  final kundli = await roxy.vedicAstrology.generateBirthChart(
    date: '1990-01-15',
    time: '14:30:00',
    latitude: place.latitude,
    longitude: place.longitude,
    timezone: NumOrString.string(place.timezone),
  );
  // `meta` is keyed by graha; its `nakshatra` is an object, so read `name`.
  final vedicMoon = kundli.meta['Moon'];
  print('Rashi ${vedicMoon?.rashi}, nakshatra ${vedicMoon?.nakshatra.name}');
  // #enddocregion quick-start
}

Future<void> languages(Roxy roxy) async {
  // #docregion languages
  final card = await roxy.tarot.getDailyCard(
    seed: 'user-42',
    date: '2026-04-22',
  );
  final hindi = await roxy.tarot.getDailyCard(
    seed: 'user-42',
    date: '2026-04-22',
    lang: Lang.hi,
  );
  print('${card.card.name}: ${card.dailyMessage}');
  print('${hindi.card.name}: ${hindi.dailyMessage}');
  // #enddocregion languages
}

Future<void> errors(Roxy roxy) async {
  // #docregion errors
  try {
    await roxy.astrology.generateNatalChart(
      date: '1990-13-45',
      time: '14:30:00',
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: const NumOrString.string('Europe/London'),
    );
  } on RoxyException catch (e) {
    print('${e.statusCode} ${e.code}: ${e.message} (${e.docUrl})');
    for (final issue in e.issues) {
      print('${issue.path}: ${issue.message}');
    }
  }
  // #enddocregion errors
}

Future<void> retries() async {
  // #docregion retries
  final roxy = Roxy(Platform.environment['ROXY_API_KEY'] ?? '', maxRetries: 4);
  try {
    final horoscope = await roxy.astrology.getDailyHoroscope(sign: Sign.leo);
    print(horoscope.love);
  } on RoxyException catch (e) {
    if (e.code == ErrorCodes.rateLimitPerMinute ||
        e.code == ErrorCodes.computeSaturated) {
      print('retry in ${e.retryAfter?.inSeconds} seconds');
    } else {
      print('${e.statusCode} ${e.code} ${e.docUrl}');
    }
  } finally {
    roxy.close();
  }
  // #enddocregion retries
}

Future<void> ownClient() async {
  // #docregion authentication
  final client = http.Client();
  final roxy = Roxy(
    Platform.environment['ROXY_API_KEY'] ?? '',
    client: client,
    timeout: const Duration(seconds: 20),
  );
  final moon = await roxy.astrology.getCurrentMoonPhase();
  print('${moon.phase} in ${moon.sign}');
  client.close();
  // #enddocregion authentication
}

/// An invalid key is a `RoxyException` like any other error response.
Future<void> invalidKey() async {
  final roxy = Roxy('not-a-real-key');
  try {
    await roxy.tarot.getDailyCard();
  } on RoxyException catch (e) {
    print('${e.statusCode} ${e.code}');
  } finally {
    roxy.close();
  }
}
