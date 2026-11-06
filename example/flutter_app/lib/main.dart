// #docregion flutter-app
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roxyapi/roxyapi.dart' as roxy;

import 'natal_chart_view.dart';

/// Your backend, which holds the API key and returns the chart JSON.
const backend = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:8080',
);

Future<roxy.NatalChartResponse> fetchChart() async {
  final response = await http.get(
    Uri.parse('$backend/?city=Paris&date=1990-01-15'),
  );
  final json = jsonDecode(utf8.decode(response.bodyBytes));
  if (json is! Map<String, Object?>) {
    throw const FormatException('expected a chart object');
  }
  return roxy.NatalChartResponse.fromJson(json);
}
// #enddocregion flutter-app

void main() => runApp(const MaterialApp(home: ChartPage()));

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FutureBuilder(
      future: fetchChart(),
      builder: (context, snapshot) {
        final chart = snapshot.data;
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        if (chart == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // #docregion flutter-render
        return Column(
          children: [
            Text('${chart.ascendant.sign} rising'),
            Expanded(child: NatalChartView(chart)),
          ],
        );
        // #enddocregion flutter-render
      },
    ),
  );
}
