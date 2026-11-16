@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../tool/namespace.dart';
import 'spec_fixture.dart';

/// The generated client read as source: each namespace field with its class, and each class's methods with their named parameters in order.
final class Surface {
  Surface(String source) {
    final namespaces = RegExp(
      r'^abstract base class RoxyNamespaces \{$(.*?)^\}$',
      multiLine: true,
      dotAll: true,
    ).firstMatch(source);
    for (final m in RegExp(
      r'^  final (\w+) (\w+);$',
      multiLine: true,
    ).allMatches(namespaces?[1] ?? '')) {
      classOf[m[2]!] = m[1]!;
      fields.add(m[2]!);
    }
    for (final c in RegExp(
      r'^final class (\w+) \{$(.*?)^\}$',
      multiLine: true,
      dotAll: true,
    ).allMatches(source)) {
      methods[c[1]!] = {
        for (final m in RegExp(
          r'^  Future<[^;{]+?>\s+(\w+)\((\{[^)]*\})?\)',
          multiLine: true,
        ).allMatches(c[2]!))
          m[1]!: [
            for (final p in RegExp(r'(\w+)\s*[,}]').allMatches(m[2] ?? ''))
              p[1]!,
          ],
      };
    }
  }

  final List<String> fields = [];
  final Map<String, String> classOf = {};
  final Map<String, Map<String, List<String>>> methods = {};
}

void main() {
  final surface = Surface(File('lib/src/api.g.dart').readAsStringSync());

  test('every spec operation is a method on the namespace of its path', () {
    final operations = committedApi.operations.toList();
    expect(operations.length, greaterThan(200));
    for (final op in operations) {
      expect(op.namespace, pathNamespace(op.path));
      final params =
          surface.methods[surface.classOf[op.namespace]]?[op.operationId];
      expect(
        params,
        isNotNull,
        reason: 'roxy.${op.namespace}.${op.operationId}',
      );
      expect(params, [
        for (final p in op.params) p.dart,
      ], reason: '${op.operationId} parameters: path, body, query, then lang');
    }
  });

  test('every spec tag is exactly one final namespace field', () {
    final namespaces = committedApi.domains.map((d) => d.namespace).toList();
    expect(namespaces.toSet(), hasLength(namespaces.length));
    expect(surface.fields, unorderedEquals(namespaces));
  });
}
