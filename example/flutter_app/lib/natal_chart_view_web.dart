// #docregion ui-web
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:roxyapi/roxyapi.dart' as roxy;
import 'package:web/web.dart' as web;

@JS('JSON.parse')
external JSAny? _parse(String text);

extension on web.HTMLElement {
  /// The response the component renders.
  external set data(JSAny? value);
}

/// The chart drawn by the `roxy-natal-chart` component, loaded by `web/index.html`.
class NatalChartView extends StatelessWidget {
  const NatalChartView(this.chart, {super.key});

  final roxy.NatalChartResponse chart;

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'roxy-natal-chart',
    onElementCreated: (element) {
      // On the web the created platform view is a DOM element.
      (element as web.HTMLElement).data = _parse(jsonEncode(chart.json));
    },
  );
}
// #enddocregion ui-web
