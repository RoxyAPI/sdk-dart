import 'dart:convert';
import 'dart:io';

import 'package:roxyapi/roxyapi.dart';

/// The backend of the Flutter example: it holds the API key and answers the app with chart
/// JSON, so the key never ships inside the app.
///
/// ```bash
/// ROXY_API_KEY=your_key dart run example/server.dart
/// ```
Future<void> main() async {
  // #docregion flutter-server
  final roxy = Roxy(Platform.environment['ROXY_API_KEY'] ?? '');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  await for (final request in server) {
    final query = request.uri.queryParameters;
    final places = await roxy.location.searchCities(
      q: query['city'] ?? 'Paris',
    );
    final place = places.cities.first;
    final chart = await roxy.astrology.generateNatalChart(
      date: query['date'] ?? '1990-01-15',
      time: query['time'] ?? '14:30:00',
      latitude: place.latitude,
      longitude: place.longitude,
      timezone: NumOrString.string(place.timezone),
    );
    request.response
      ..headers.contentType = ContentType.json
      ..headers.set('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(chart.json));
    await request.response.close();
  }
  // #enddocregion flutter-server
}
