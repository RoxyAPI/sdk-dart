// #docregion ui-mobile
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:roxyapi/roxyapi.dart' as roxy;
import 'package:webview_flutter/webview_flutter.dart';

const roxyUi = 'https://cdn.jsdelivr.net/npm/@roxyapi/ui@1/dist/cdn/roxy-ui.js';

/// The chart drawn by the `roxy-natal-chart` component inside a WebView.
class NatalChartView extends StatefulWidget {
  const NatalChartView(this.chart, {super.key});

  final roxy.NatalChartResponse chart;

  @override
  State<NatalChartView> createState() => _NatalChartViewState();
}

class _NatalChartViewState extends State<NatalChartView> {
  late final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(page(widget.chart));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: controller);
}

/// A page holding the chart data and nothing else: no key ever reaches the WebView.
String page(roxy.NatalChartResponse chart) {
  // Escaped so no string inside the chart can close the data block.
  final data = jsonEncode(chart.json)
      .replaceAll('<', r'\u003c')
      .replaceAll('>', r'\u003e')
      .replaceAll('&', r'\u0026');
  return '<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1">'
      '<script src="$roxyUi" defer></script>'
      '<roxy-natal-chart><script type="application/json" class="roxy-data">$data</script>'
      '</roxy-natal-chart>';
}
// #enddocregion ui-mobile
