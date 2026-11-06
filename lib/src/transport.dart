import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'exception.dart';
import 'never_sent.dart' if (dart.library.io) 'never_sent_io.dart';
import 'version.dart';

/// Waits for [delay]. Injected so a test controls the clock.
typedef Sleep = Future<void> Function(Duration delay);

const _retryStatuses = {429, 500, 502, 503, 504};

/// Sends one API call: the key and SDK headers, the JSON body, the retries, and the decoding
/// of the response or the error.
final class Transport {
  /// Creates a transport. Every argument past [apiKey] and [baseUrl] has the documented
  /// default of `Roxy`.
  Transport({
    required String apiKey,
    required Uri baseUrl,
    http.Client? client,
    this.maxRetries = 2,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.timeout,
    Sleep? sleep,
    double Function()? random,
    DateTime Function()? now,
  }) : _apiKey = apiKey,
       _baseUrl = baseUrl,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _sleep = sleep ?? Future<void>.delayed,
       _random = random ?? math.Random().nextDouble,
       _now = now ?? DateTime.now {
    if (maxRetries < 0) throw ArgumentError.value(maxRetries, 'maxRetries');
  }

  final String _apiKey;
  final Uri _baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final Sleep _sleep;
  final double Function() _random;
  final DateTime Function() _now;

  /// Retries after the first attempt; 0 never retries.
  final int maxRetries;

  /// Base of the backoff, and the most jitter added to a `Retry-After` wait.
  final Duration initialDelay;

  /// Longest wait between attempts. A `Retry-After` above it is not waited for.
  final Duration maxDelay;

  /// Most time one call may take, every retry included. `null` waits as long as it takes.
  final Duration? timeout;

  /// Sends [method] to [path] and returns the decoded JSON of a 2xx response.
  ///
  /// Throws [RoxyException] on any other status, and rethrows a network failure.
  Future<Object?> send(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Map<String, Object?>? body,
  }) async {
    final url = _baseUrl.replace(
      path: '${_baseUrl.path}$path',
      queryParameters: query.isEmpty
          ? null
          : {for (final MapEntry(:key, :value) in query.entries) key: '$value'},
    );
    final bytes = body == null ? null : utf8.encode(jsonEncode(body));
    final limit = timeout;
    final deadline = limit == null ? null : _now().add(limit);
    final expired = Completer<void>();
    final timer = limit == null ? null : Timer(limit, expired.complete);
    try {
      for (var attempt = 0; ; attempt++) {
        final last = attempt >= maxRetries;
        final request = http.AbortableRequest(
          method,
          url,
          abortTrigger: timer == null ? null : expired.future,
        );
        request.headers.addAll({
          'X-API-Key': _apiKey,
          'X-SDK-Client': 'roxy-sdk-dart/$version',
          'Accept': 'application/json',
          if (bytes != null) 'Content-Type': 'application/json',
        });
        if (bytes != null) request.bodyBytes = bytes;

        http.StreamedResponse? response;
        try {
          response = await _client.send(request);
        } on Object catch (error) {
          if (last || !neverSent(error)) rethrow;
        }

        var delay = initialDelay * math.pow(2, attempt).toDouble();
        if (delay > maxDelay) delay = maxDelay;
        delay *= _random();
        if (response != null) {
          if (last || !_retryStatuses.contains(response.statusCode)) {
            return await _finish(response);
          }
          final wait = retryAfter(response.headers['retry-after'], _now());
          if (wait != null) {
            if (wait > maxDelay) return await _finish(response);
            delay = wait + initialDelay * _random();
            if (delay > maxDelay) delay = maxDelay;
          }
        }
        if (deadline != null && _now().add(delay).isAfter(deadline)) {
          if (response != null) return await _finish(response);
          throw TimeoutException('roxyapi: no time left to retry', limit);
        }
        // Release the connection held by a response that is certain to be discarded.
        await response?.stream.listen(null).cancel();
        await _sleep(delay);
      }
    } finally {
      timer?.cancel();
    }
  }

  Future<Object?> _finish(http.StreamedResponse response) async {
    final text = utf8.decode(
      await response.stream.toBytes(),
      allowMalformed: true,
    );
    if (response.statusCode ~/ 100 == 2) {
      return text.isEmpty ? null : jsonDecode(text);
    }
    final error = _errorBody(text);
    throw RoxyException(
      statusCode: response.statusCode,
      code: _text(error?['code']) ?? 'error',
      message:
          _text(error?['error']) ??
          response.reasonPhrase ??
          'HTTP ${response.statusCode}',
      docUrl: _text(error?['doc_url']),
      retryAfter: retryAfter(response.headers['retry-after'], _now()),
      body: error,
    );
  }

  /// The JSON error body, or `null` for a body that is not one, such as a bare 413.
  static Map<String, Object?>? _errorBody(String text) {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String? _text(Object? value) => value is String ? value : null;

  /// Closes the HTTP client, unless the caller passed their own.
  void close() {
    if (_ownsClient) _client.close();
  }
}

/// The wait a `Retry-After` header value asks for: whole seconds or an HTTP date.
Duration? retryAfter(String? header, DateTime now) {
  final value = header?.trim();
  if (value == null || value.isEmpty) return null;
  if (RegExp(r'^\d+$').hasMatch(value)) {
    return Duration(seconds: int.parse(value));
  }
  final date = _httpDate.firstMatch(value);
  if (date == null) return null;
  final month = _months.indexOf(date[2] ?? '') + 1;
  if (month == 0) return null;
  final at = DateTime.utc(
    int.parse(date[3] ?? ''),
    month,
    int.parse(date[1] ?? ''),
    int.parse(date[4] ?? ''),
    int.parse(date[5] ?? ''),
    int.parse(date[6] ?? ''),
  );
  final wait = at.difference(now);
  return wait.isNegative ? Duration.zero : wait;
}

/// The IMF-fixdate form of an HTTP date, the one a server sends: `Thu, 01 Jan 2026 00:00:10 GMT`.
final _httpDate = RegExp(
  r'^[A-Za-z]{3}, (\d{2}) ([A-Za-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
);

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
