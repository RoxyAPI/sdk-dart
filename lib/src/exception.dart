import 'json.dart';
import 'models.g.dart';

/// An error response from the API: any status outside 2xx.
///
/// Switch on [code], a stable identifier; [message] is readable text and may change. The codes
/// the API documents are constants on `ErrorCodes`, and a code added later arrives here as a
/// plain string.
final class RoxyException implements Exception {
  /// Creates an exception for an error response.
  const RoxyException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.docUrl,
    this.retryAfter,
    this.body,
  });

  /// The HTTP status of the response.
  final int statusCode;

  /// The machine-readable error code, such as `validation_error`.
  final String code;

  /// The human-readable error text.
  final String message;

  /// The documentation page for [code].
  final String? docUrl;

  /// How long the response asks the caller to wait before sending again, from `Retry-After`.
  final Duration? retryAfter;

  /// The decoded error body, or `null` when the response carried no JSON object.
  final Map<String, Object?>? body;

  /// Every failing field of a validation error, each with its `path` and `message`. Empty
  /// for any other error.
  List<ValidationIssue> get issues {
    final error = body;
    return error != null && error['issues'] is List<Object?>
        ? read(error, 'issues', listOf(model(ValidationIssue.fromJson)))
        : const [];
  }

  @override
  String toString() => 'RoxyException($statusCode, $code): $message';
}
