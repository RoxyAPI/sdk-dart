import 'package:http/http.dart' as http;

import 'api.g.dart';
import 'transport.dart';

/// The RoxyAPI client: one namespace per domain, one method per endpoint.
///
/// ```dart
/// final roxy = Roxy('YOUR_API_KEY');
/// final horoscope = await roxy.astrology.getDailyHoroscope(sign: Sign.aries);
/// print(horoscope.overview);
/// roxy.close();
/// ```
///
/// Every method returns the typed response and throws `RoxyException` on an error response.
/// A request is sent again up to [maxRetries] times after a 429, 500, 502, 503 or 504, or after
/// a connection that was never made.
final class Roxy extends RoxyNamespaces {
  /// Creates a client for [apiKey].
  ///
  /// Pass [client] to send through your own HTTP client, which [close] then leaves open.
  /// [maxRetries] retries after the first attempt (0 turns retries off). The wait follows
  /// `Retry-After` when the response sends it, and a full-jitter backoff from [initialDelay]
  /// up to [maxDelay] otherwise; a `Retry-After` longer than [maxDelay] is not waited for.
  /// [timeout] caps one call, every retry included.
  factory Roxy(
    String apiKey, {
    http.Client? client,
    int maxRetries = 2,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 30),
    Duration? timeout,
  }) => Roxy._(
    Transport(
      apiKey: apiKey,
      baseUrl: Uri.parse(apiBaseUrl),
      client: client,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
      timeout: timeout,
    ),
  );

  Roxy._(this._transport) : super(_transport);

  final Transport _transport;

  /// Closes the HTTP client this instance created. Calls after [close] fail.
  void close() => _transport.close();
}
