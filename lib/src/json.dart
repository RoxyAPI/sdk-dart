import 'dart:collection';

/// A value the API accepts as either a number or a string, such as a `timezone` given as a UTC
/// offset in hours (`5.5`) or as an IANA name (`'Europe/London'`).
extension type const NumOrString._(Object value) implements Object {
  /// A number, such as a UTC offset in hours.
  const NumOrString.number(num value) : this._(value);

  /// A string, such as an IANA timezone name.
  const NumOrString.string(String value) : this._(value);

  /// The number, or `null` when the value is a string.
  num? get asNum => switch (value) {
    final num n => n,
    _ => null,
  };

  /// The string, or `null` when the value is a number.
  String? get asString => switch (value) {
    final String s => s,
    _ => null,
  };
}

/// Reads one JSON value as a `T`, naming [field] when the value has another type.
typedef Decode<T> = T Function(Object? value, String field);

FormatException _wrong(String expected, Object? value, String field) =>
    FormatException(
      'roxyapi: expected $expected at "$field", got ${value.runtimeType}',
    );

/// The value of a required field.
T read<T>(Map<String, Object?> json, String key, Decode<T> decode) =>
    decode(json[key], key);

/// The value of an optional or nullable field, `null` when it is absent or null.
T? readOrNull<T extends Object>(
  Map<String, Object?> json,
  String key,
  Decode<T> decode,
) {
  final value = json[key];
  return value == null ? null : decode(value, key);
}

String asString(Object? value, String field) =>
    value is String ? value : throw _wrong('String', value, field);

bool asBool(Object? value, String field) =>
    value is bool ? value : throw _wrong('bool', value, field);

num asNum(Object? value, String field) =>
    value is num ? value : throw _wrong('num', value, field);

int asInt(Object? value, String field) => switch (value) {
  final int i => i,
  final double d when d.isFinite && d == d.truncateToDouble() => d.toInt(),
  _ => throw _wrong('int', value, field),
};

Object? asAny(Object? value, String field) => value;

Map<String, Object?> asObject(Object? value, String field) =>
    value is Map<String, Object?>
    ? value
    : throw _wrong('object', value, field);

NumOrString asNumOrString(Object? value, String field) => switch (value) {
  final num n => NumOrString.number(n),
  final String s => NumOrString.string(s),
  _ => throw _wrong('number or String', value, field),
};

/// Reads a JSON object as the model built by [make].
Decode<T> model<T>(T Function(Map<String, Object?> json) make) =>
    (value, field) => make(asObject(value, field));

/// Reads `null` as `null` and anything else with [decode].
Decode<T?> nullable<T extends Object>(Decode<T> decode) =>
    (value, field) => value == null ? null : decode(value, field);

/// Reads a JSON array as a read-only list that decodes each element when it is read.
Decode<List<T>> listOf<T>(Decode<T> item) =>
    (value, field) => value is List<Object?>
    ? _JsonList(value, field, item)
    : throw _wrong('list', value, field);

/// Reads a JSON object as a read-only map that decodes each value when it is read.
Decode<Map<String, T>> mapOf<T>(Decode<T> item) =>
    (value, field) => value is Map<String, Object?>
    ? _JsonMap(value, field, item)
    : throw _wrong('object', value, field);

final class _JsonList<T> extends ListBase<T> {
  _JsonList(this._raw, this._field, this._item);
  final List<Object?> _raw;
  final String _field;
  final Decode<T> _item;

  @override
  int get length => _raw.length;

  @override
  set length(int value) =>
      throw UnsupportedError('a response list is read-only');

  @override
  T operator [](int index) => _item(_raw[index], '$_field[$index]');

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('a response list is read-only');
}

final class _JsonMap<T> extends UnmodifiableMapBase<String, T> {
  _JsonMap(this._raw, this._field, this._item);
  final Map<String, Object?> _raw;
  final String _field;
  final Decode<T> _item;

  @override
  Iterable<String> get keys => _raw.keys;

  @override
  T? operator [](Object? key) => key is String && _raw.containsKey(key)
      ? _item(_raw[key], '$_field.$key')
      : null;
}
