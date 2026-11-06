/// One walk of the OpenAPI spec into the operation and type model that the code emitter, the
/// docs sync and the tests share. Anything the model cannot map fails here, loudly, naming the
/// spec location, so a spec change that needs a generator change never ships a silent guess.
library;

import 'dart:convert';

import 'namespace.dart';

typedef Json = Map<String, Object?>;

Never fail(String message) => throw StateError('generate: $message');

Json asJson(Object? value, String where) =>
    value is Map<String, Object?> ? value : fail('$where is not an object');

List<Object?> asJsonList(Object? value, String where) =>
    value is List<Object?> ? value : fail('$where is not a list');

String? asText(Object? value) => value is String ? value : null;

const _reserved = {
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'while',
  'with',
  'hashCode',
  'runtimeType',
  'toString',
  'noSuchMethod',
  'bool',
  'double',
  'dynamic',
  'int',
  'num',
};

List<String> _words(String text) => [
  for (final part in text.split(RegExp('[^A-Za-z0-9]+')))
    if (part.isNotEmpty)
      part == part.toUpperCase() && part.length > 1
          ? part[0] + part.substring(1).toLowerCase()
          : part,
];

String _capitalize(String word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);

/// `doc_url` is `DocUrl`, `SEMI_SEXTILE` is `SemiSextile`, `birthData` is `BirthData`.
String pascal(String text) => _words(text).map(_capitalize).join();

/// A Dart member name for a wire name: lowerCamelCase, a digit-led name prefixed with `v`, and a
/// reserved word or an `Object` member suffixed with `$`.
String memberName(String wire, {Set<String> taken = const {}}) {
  final p = pascal(wire);
  if (p.isEmpty) fail('cannot name the wire value "$wire"');
  var name = p[0].toLowerCase() + p.substring(1);
  if (RegExp('^[0-9]').hasMatch(name)) name = 'v${_capitalize(name)}';
  return _reserved.contains(name) || taken.contains(name) ? '$name\$' : name;
}

/// A Dart enum member for a wire value; also avoids the members every Dart enum and the
/// generated `wire` field already define.
String enumMember(String wire) =>
    memberName(wire, taken: const {'values', 'index', 'name', 'wire'});

/// Where a schema is read: request types get constructors and enums, response types getters.
enum Side { request, response }

/// A Dart type for a schema, independent of where it is emitted.
sealed class TypeRef {
  const TypeRef({this.nullable = false});
  final bool nullable;
  TypeRef withNullable(bool value);
}

enum Scalar { string, integer, number, boolean, any, object }

final class ScalarType extends TypeRef {
  const ScalarType(this.scalar, {super.nullable});
  final Scalar scalar;
  @override
  ScalarType withNullable(bool value) => ScalarType(scalar, nullable: value);
}

final class NumOrStringType extends TypeRef {
  const NumOrStringType({super.nullable});
  @override
  NumOrStringType withNullable(bool value) => NumOrStringType(nullable: value);
}

final class EnumType extends TypeRef {
  const EnumType(this.occurrence, {super.nullable});
  final EnumOccurrence occurrence;
  @override
  EnumType withNullable(bool value) => EnumType(occurrence, nullable: value);
}

final class ModelType extends TypeRef {
  const ModelType(this.name, {super.nullable});
  final String name;
  @override
  ModelType withNullable(bool value) => ModelType(name, nullable: value);
}

final class ListType extends TypeRef {
  const ListType(this.item, {super.nullable});
  final TypeRef item;
  @override
  ListType withNullable(bool value) => ListType(item, nullable: value);
}

final class MapType extends TypeRef {
  const MapType(this.value, {super.nullable});
  final TypeRef value;
  @override
  MapType withNullable(bool value) => MapType(this.value, nullable: value);
}

/// One request enum as the spec declares it: the property or parameter name, its values, and
/// the first operation that declares it.
final class EnumOccurrence {
  EnumOccurrence(this.key, this.values, this.operationId);
  final String key;
  final List<String> values;
  final String operationId;
  late String name;
}

final class EnumDef {
  EnumDef(this.name, this.key, this.values);
  final String name;
  final String key;
  final List<String> values;
}

final class Field {
  Field(this.wire, this.dart, this.schema, {required this.required});
  final String wire;
  final String dart;
  final Json schema;
  final bool required;
  final Map<Side, TypeRef> types = {};
  String? get description => asText(schema['description']);
}

final class ModelDef {
  ModelDef(this.name, this.schema, this.fields);
  final String name;
  final Json schema;
  final List<Field> fields;
  final Set<Side> sides = {};
  String? get description => asText(schema['description']);
}

enum ParamSource { path, body, query }

final class Param {
  Param(
    this.wire,
    this.dart,
    this.source,
    this.schema,
    this.type, {
    required this.required,
    this.description,
    this.example,
  });
  final String wire;
  final String dart;
  final ParamSource source;
  final Json schema;
  final TypeRef type;
  final bool required;
  final String? description;
  final Object? example;
}

final class Operation {
  Operation({
    required this.path,
    required this.verb,
    required this.operationId,
    required this.namespace,
    required this.tag,
    required this.summary,
    required this.description,
    required this.params,
    required this.hasBody,
    required this.response,
  });
  final String path;
  final String verb;
  final String operationId;
  final String namespace;
  final String tag;
  final String? summary;
  final String? description;
  final List<Param> params;
  final bool hasBody;
  final TypeRef response;
}

final class Domain {
  Domain(this.tag, this.namespace, this.description, this.operations);
  final String tag;
  final String namespace;
  final String? description;
  final List<Operation> operations;

  /// `Western Astrology` is `https://roxyapi.com/api-reference/western-astrology`.
  String get referenceUrl =>
      'https://roxyapi.com/api-reference/${tag.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';

  /// The first sentence of the tag description, capped at 120 characters, for tables.
  String get summary {
    final text = (description ?? '').trim();
    if (text.isEmpty) return tag;
    final first = text
        .split(RegExp(r'\.\s+'))
        .first
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return first.length > 120 ? '${first.substring(0, 117).trim()}...' : first;
  }
}

final class ErrorCode {
  ErrorCode(this.code, this.status, this.meaning);
  final String code;
  final int? status;
  final String meaning;
}

/// The whole spec as the SDK exposes it.
final class Api {
  Api._(this.spec);

  final Json spec;
  final List<Domain> domains = [];
  final Map<String, ModelDef> models = {};
  final List<EnumDef> enums = [];
  final List<ErrorCode> errorCodes = [];
  final List<EnumOccurrence> _occurrences = [];

  /// The base URL every request goes to, from `servers[0].url`.
  String get baseUrl =>
      asText(
        asJson(
          asJsonList(spec['servers'], 'servers').first,
          'servers[0]',
        )['url'],
      ) ??
      fail('servers[0].url is missing');

  static Api read(Json spec) {
    final api = Api._(spec);
    api._walk();
    api._nameEnums();
    return api;
  }

  Iterable<Operation> get operations => domains.expand((d) => d.operations);

  /// The widest `lang` enum. Every other `lang` declaration is a subset of it, so one `Lang`
  /// enum serves every operation; a composite operation such as a report accepts only the
  /// codes all of its domains write.
  EnumDef get langEnum => enums.firstWhere(
    (e) => e.key == 'lang',
    orElse: () => fail('no operation takes a lang parameter'),
  );

  Json _deref(Json schema, String where) {
    var current = schema;
    for (var depth = 0; current['\$ref'] != null; depth++) {
      if (depth > 8) fail('$where: \$ref chain too deep');
      current = _component(
        asText(current['\$ref']) ?? fail('$where: bad \$ref'),
      );
    }
    return current;
  }

  Json _component(String ref) {
    const prefix = '#/components/schemas/';
    if (!ref.startsWith(prefix)) fail('unsupported \$ref $ref');
    final schemas = asJson(
      asJson(spec['components'], 'components')['schemas'],
      'schemas',
    );
    return asJson(schemas[ref.substring(prefix.length)], ref);
  }

  void _walk() {
    final info = asJson(spec['info'], 'info');
    for (final raw in asJsonList(info['x-error-codes'], 'info.x-error-codes')) {
      final entry = asJson(raw, 'x-error-codes[]');
      final status = entry['status'];
      errorCodes.add(
        ErrorCode(
          asText(entry['code']) ?? fail('x-error-codes entry without code'),
          status is int ? status : null,
          asText(entry['meaning']) ?? '',
        ),
      );
    }
    if (errorCodes.isEmpty) fail('info["x-error-codes"] is empty');

    final byTag = <String, List<Operation>>{};
    final paths = asJson(spec['paths'], 'paths');
    for (final MapEntry(key: path, value: rawItem) in paths.entries) {
      for (final MapEntry(key: verb, value: rawOp) in asJson(
        rawItem,
        path,
      ).entries) {
        if (verb != 'get' && verb != 'post') {
          fail('$path has an unsupported key "$verb"');
        }
        final op = _operation(path, verb, asJson(rawOp, '$verb $path'));
        byTag.putIfAbsent(op.tag, () => []).add(op);
      }
    }
    for (final rawTag in asJsonList(spec['tags'], 'tags')) {
      final tag = asJson(rawTag, 'tags[]');
      final name = asText(tag['name']) ?? fail('tag without a name');
      final ops =
          byTag.remove(name) ??
          fail('tag "$name" is declared but has no operations');
      final namespaces = {for (final op in ops) op.namespace};
      if (namespaces.length != 1) {
        fail(
          'tag "$name" spans ${namespaces.length} path segments ($namespaces), expected one',
        );
      }
      domains.add(
        Domain(name, namespaces.single, asText(tag['description']), ops),
      );
    }
    if (byTag.isNotEmpty) {
      fail('operations carry undeclared tags: ${byTag.keys}');
    }
    final seen = <String>{};
    for (final op in operations) {
      if (!seen.add(op.operationId)) {
        fail('duplicate operationId ${op.operationId}');
      }
    }
    _validationIssue(paths);
  }

  /// The model of one entry of `issues` in a 400 body. Every operation declares the same 400
  /// schema, so `RoxyException.issues` has one type; a divergence fails generation.
  void _validationIssue(Json paths) {
    final schemas = <String, Json>{};
    for (final MapEntry(key: path, value: item) in paths.entries) {
      for (final MapEntry(key: verb, value: op) in asJson(item, path).entries) {
        final where = '${verb.toUpperCase()} $path 400';
        final responses = asJson(asJson(op, where)['responses'], where);
        final bad = asJson(responses['400'], where);
        final media = asJson(
          asJson(bad['content'], where)['application/json'],
          where,
        );
        final schema = _deref(asJson(media['schema'], where), where);
        schemas.putIfAbsent(jsonEncode(schema), () => schema);
      }
    }
    if (schemas.length != 1) {
      fail('the 400 schemas diverge (${schemas.length} shapes)');
    }
    final issues = asJson(
      asJson(schemas.values.single['properties'], '400')['issues'],
      'issues',
    );
    final item = asJson(issues['items'], '400 issues items');
    _model(
      validationIssue,
      item,
      Side.response,
      '400 issues',
      'validationIssue',
    );
  }

  /// The type name of one entry of `issues` in a 400 body.
  static const validationIssue = 'ValidationIssue';

  Operation _operation(String path, String verb, Json op) {
    final where = '${verb.toUpperCase()} $path';
    final operationId =
        asText(op['operationId']) ?? fail('$where has no operationId');
    final tags = asJsonList(op['tags'] ?? const <Object?>[], '$where tags');
    if (tags.isEmpty) fail('$where has no tag');
    final params = <Param>[];
    final names = <String, String>{};
    void add(Param p) {
      final previous = names[p.dart];
      if (previous != null) {
        fail(
          '$operationId: parameter "${p.dart}" comes from both $previous and ${p.source.name}',
        );
      }
      names[p.dart] = p.source.name;
      params.add(p);
    }

    final rawParams = [
      for (final p in asJsonList(
        op['parameters'] ?? const <Object?>[],
        '$where parameters',
      ))
        asJson(p, '$where parameter'),
    ];
    Param fromParameter(Json p, ParamSource source) {
      final wire = asText(p['name']) ?? fail('$where: parameter without name');
      final schema = asJson(p['schema'], '$where $wire schema');
      return Param(
        wire,
        memberName(wire),
        source,
        schema,
        typeOf(
          schema,
          Side.request,
          '${pascal(operationId)}${pascal(wire)}',
          '$operationId.$wire',
          operationId,
          key: wire,
        ),
        required: p['required'] == true,
        description: asText(p['description']) ?? asText(schema['description']),
        example: p['example'] ?? schema['example'],
      );
    }

    for (final p in rawParams.where((p) => p['in'] == 'path')) {
      if (p['required'] != true) {
        fail('$operationId: path parameter is not required');
      }
      add(fromParameter(p, ParamSource.path));
    }
    for (final p in rawParams) {
      if (p['in'] != 'path' && p['in'] != 'query') {
        fail('$operationId: parameter in ${p['in']}');
      }
    }

    final body = op['requestBody'];
    if (body != null) {
      final content = asJson(
        asJson(body, '$where requestBody')['content'],
        '$where content',
      );
      if (content.keys.length != 1 || content['application/json'] == null) {
        fail('$operationId: request body is not only application/json');
      }
      final schemaRef = asJson(
        asJson(content['application/json'], where)['schema'],
        where,
      );
      final ref = asText(schemaRef['\$ref']);
      final schema = _deref(schemaRef, '$operationId body');
      final props = asJson(
        schema['properties'] ?? <String, Object?>{},
        '$operationId body',
      );
      final required = {
        for (final r in asJsonList(
          schema['required'] ?? const <Object?>[],
          where,
        ))
          asText(r),
      };
      final parent = ref == null
          ? '${pascal(operationId)}Request'
          : ref.split('/').last;
      for (final MapEntry(key: wire, value: raw) in props.entries) {
        final propSchema = asJson(raw, '$operationId body.$wire');
        add(
          Param(
            wire,
            memberName(wire),
            ParamSource.body,
            propSchema,
            typeOf(
              propSchema,
              Side.request,
              '$parent${pascal(wire)}',
              '$operationId body.$wire',
              operationId,
              key: wire,
            ),
            required: required.contains(wire),
            description: asText(_deref(propSchema, wire)['description']),
            example:
                propSchema['example'] ?? _deref(propSchema, wire)['example'],
          ),
        );
      }
    }
    final query = rawParams.where((p) => p['in'] == 'query').toList();
    for (final p in query.where((p) => p['name'] != 'lang')) {
      add(fromParameter(p, ParamSource.query));
    }
    for (final p in query.where((p) => p['name'] == 'lang')) {
      add(fromParameter(p, ParamSource.query));
    }

    final responses = asJson(op['responses'], '$where responses');
    final ok = asJson(responses['200'], '$where 200');
    final okContent = asJson(ok['content'], '$where 200 content');
    final okSchema = asJson(
      asJson(
        okContent['application/json'],
        '$where 200 application/json',
      )['schema'],
      '$where 200 schema',
    );
    final response = typeOf(
      okSchema,
      Side.response,
      '${pascal(operationId)}Response',
      '$operationId response',
      operationId,
    );
    if (response.nullable) fail('$operationId: a nullable response root');

    return Operation(
      path: path,
      verb: verb,
      operationId: operationId,
      namespace: pathNamespace(path),
      tag: asText(tags.first) ?? fail('$where tag is not a string'),
      summary: asText(op['summary']),
      description: asText(op['description']),
      params: params,
      hasBody: body != null,
      response: response,
    );
  }

  /// The Dart type of [schema] read on [side]. [hint] names an inline object, [key] and
  /// [operationId] identify a request enum.
  TypeRef typeOf(
    Json schema,
    Side side,
    String hint,
    String where,
    String operationId, {
    String? key,
  }) {
    final ref = asText(schema['\$ref']);
    if (ref != null) {
      return _model(
        ref.split('/').last,
        _component(ref),
        side,
        where,
        operationId,
      );
    }

    final allOf = schema['allOf'];
    if (allOf != null) {
      final parts = [
        for (final p in asJsonList(allOf, where)) asJson(p, where),
      ];
      final refs = parts.where((p) => p['\$ref'] != null).toList();
      final shaped = parts.where(
        (p) => p['type'] != null || p['properties'] != null,
      );
      if (refs.length != 1 || shaped.isNotEmpty) {
        fail('$where: allOf beyond one \$ref');
      }
      return typeOf(refs.single, side, hint, where, operationId);
    }

    var nullable = false;
    final rawType = schema['type'];
    final types = <String>[
      if (rawType is String) rawType,
      if (rawType is List<Object?>)
        for (final t in rawType) asText(t) ?? fail('$where: bad type list'),
    ];
    if (types.remove('null')) nullable = true;

    final union = schema['oneOf'] ?? schema['anyOf'];
    if (union != null) {
      final alts = [
        for (final a in asJsonList(union, where))
          _deref(asJson(a, where), where),
      ];
      final altTypes = <String>{};
      for (final a in alts) {
        final t = a['type'];
        if (t is! String) fail('$where: union alternative without one type');
        if (t == 'null') {
          nullable = true;
        } else {
          altTypes.add(t);
        }
      }
      final concrete = alts.where((a) => a['type'] != 'null').toList();
      if (altTypes.length == 2 && altTypes.containsAll(['number', 'string'])) {
        return NumOrStringType(nullable: nullable);
      }
      if (altTypes.length == 1 &&
          altTypes.single == 'string' &&
          concrete.every((a) => a['enum'] != null)) {
        final values = [
          for (final a in concrete)
            for (final v in asJsonList(a['enum'], where))
              asText(v) ?? fail('$where: enum'),
        ];
        return _string(
          {'type': 'string', 'enum': values},
          side,
          nullable,
          where,
          key,
          operationId,
        );
      }
      if (concrete.length == 1) {
        return typeOf(
          concrete.single,
          side,
          hint,
          where,
          operationId,
          key: key,
        ).withNullable(nullable);
      }
      fail('$where: unsupported union of $altTypes');
    }

    if (types.length > 1) fail('$where: more than one non-null type $types');
    final type = types.isEmpty ? null : types.single;
    switch (type) {
      case 'string':
        return _string(schema, side, nullable, where, key, operationId);
      case 'integer':
        return ScalarType(Scalar.integer, nullable: nullable);
      case 'number':
        return ScalarType(Scalar.number, nullable: nullable);
      case 'boolean':
        return ScalarType(Scalar.boolean, nullable: nullable);
      case 'array':
        final items = asJson(
          schema['items'] ?? <String, Object?>{},
          '$where items',
        );
        return ListType(
          typeOf(items, side, '${hint}Item', '$where[]', operationId, key: key),
          nullable: nullable,
        );
      case 'object':
        break;
      case null:
        if (schema['properties'] == null &&
            schema['additionalProperties'] == null) {
          if (schema['enum'] != null) {
            return _string(schema, side, nullable, where, key, operationId);
          }
          return const ScalarType(Scalar.any, nullable: true);
        }
      default:
        fail('$where: unsupported type $type');
    }
    final props = schema['properties'];
    final extra = schema['additionalProperties'];
    if (props != null && asJson(props, where).isNotEmpty) {
      if (extra is Map && extra.isNotEmpty) {
        fail('$where: both properties and additionalProperties');
      }
      return _model(
        hint,
        schema,
        side,
        where,
        operationId,
      ).withNullable(nullable);
    }
    if (extra is Map<String, Object?>) {
      final value = extra.isEmpty
          ? const ScalarType(Scalar.any, nullable: true)
          : typeOf(extra, side, '${hint}Value', '$where{}', operationId);
      return MapType(value, nullable: nullable);
    }
    return ScalarType(Scalar.object, nullable: nullable);
  }

  TypeRef _string(
    Json schema,
    Side side,
    bool nullable,
    String where,
    String? key,
    String operationId,
  ) {
    final rawEnum = schema['enum'];
    if (side == Side.response || rawEnum == null) {
      return ScalarType(Scalar.string, nullable: nullable);
    }
    if (key == null) fail('$where: an enum with no name');
    final values = <String>[];
    for (final v in asJsonList(rawEnum, where)) {
      if (v == null) {
        nullable = true;
      } else {
        values.add(asText(v) ?? fail('$where: a non-string enum value'));
      }
    }
    final occurrence = EnumOccurrence(key, values, operationId);
    _occurrences.add(occurrence);
    return EnumType(occurrence, nullable: nullable);
  }

  ModelType _model(
    String name,
    Json schema,
    Side side,
    String where,
    String operationId,
  ) {
    final existing = models[name];
    if (existing != null) {
      if (!identical(existing.schema, schema)) {
        fail('$where: the type name $name is taken');
      }
    } else {
      final props = asJson(schema['properties'] ?? <String, Object?>{}, where);
      final required = {
        for (final r in asJsonList(
          schema['required'] ?? const <Object?>[],
          where,
        ))
          asText(r),
      };
      final taken = <String>{'json', 'fromJson'};
      final fields = <Field>[];
      for (final MapEntry(key: wire, value: raw) in props.entries) {
        final dart = memberName(wire, taken: taken);
        if (!taken.add(dart)) fail('$name: two properties map to "$dart"');
        fields.add(
          Field(
            wire,
            dart,
            asJson(raw, '$name.$wire'),
            required: required.contains(wire),
          ),
        );
      }
      models[name] = ModelDef(name, schema, fields);
    }
    final model = models[name] ?? fail('unreachable');
    if (model.sides.add(side)) {
      for (final field in model.fields) {
        field.types[side] = typeOf(
          field.schema,
          side,
          '$name${pascal(field.wire)}',
          '$name.${field.wire}',
          operationId,
          key: field.wire,
        );
      }
    }
    return ModelType(name);
  }

  /// Request enums sharing a name share one Dart enum when every declaration is a subset of
  /// the widest one; otherwise each distinct value set is named after the first operation that
  /// declares it.
  void _nameEnums() {
    final byKey = <String, List<EnumOccurrence>>{};
    for (final o in _occurrences) {
      byKey.putIfAbsent(o.key, () => []).add(o);
    }
    final taken = <String>{
      ...models.keys,
      'Roxy',
      'RoxyException',
      'NumOrString',
      'ErrorCodes',
    };
    void define(
      String name,
      String key,
      List<String> values,
      Iterable<EnumOccurrence> uses,
    ) {
      if (!taken.add(name)) fail('the enum name $name is taken');
      final members = <String>{};
      for (final v in values) {
        if (!members.add(enumMember(v))) {
          fail('enum $name: two values map to one member');
        }
      }
      enums.add(EnumDef(name, key, values));
      for (final u in uses) {
        u.name = name;
      }
    }

    for (final MapEntry(key: key, value: uses) in byKey.entries) {
      final widest = uses.reduce(
        (a, b) => b.values.length > a.values.length ? b : a,
      );
      if (uses.every((u) => widest.values.toSet().containsAll(u.values))) {
        define(pascal(key), key, widest.values, uses);
        continue;
      }
      final groups = <String, List<EnumOccurrence>>{};
      for (final u in uses) {
        groups
            .putIfAbsent(
              (u.values.toSet().toList()..sort()).join('\u0000'),
              () => [],
            )
            .add(u);
      }
      for (final group in groups.values) {
        define(
          '${pascal(group.first.operationId)}${pascal(key)}',
          key,
          group.first.values,
          group,
        );
      }
    }
    enums.sort((a, b) => a.name.compareTo(b.name));
  }
}
