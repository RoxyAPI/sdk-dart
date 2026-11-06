@TestOn('vm')
library;

import 'dart:mirrors';

import 'package:roxyapi/roxyapi.dart';
import 'package:test/test.dart';

import '../tool/namespace.dart';
import 'spec_fixture.dart';

void main() {
  final roxy = Roxy('test-key');
  tearDownAll(roxy.close);
  final client = reflect(roxy);

  test('every spec operation is a method on the namespace of its path', () {
    final operations = committedApi.operations.toList();
    expect(operations.length, greaterThan(200));
    for (final op in operations) {
      expect(op.namespace, pathNamespace(op.path));
      final namespace = client.getField(Symbol(op.namespace));
      final method = namespace.type.instanceMembers[Symbol(op.operationId)];
      expect(
        method,
        isNotNull,
        reason: 'roxy.${op.namespace}.${op.operationId}',
      );
      expect(
        [
          for (final p in method?.parameters ?? <ParameterMirror>[])
            MirrorSystem.getName(p.simpleName),
        ],
        [for (final p in op.params) p.dart],
        reason: '${op.operationId} parameters: path, body, query, then lang',
      );
      expect(method?.parameters.every((p) => p.isNamed), isTrue);
    }
  });

  test('every spec tag is exactly one namespace, created once per client', () {
    final namespaces = committedApi.domains.map((d) => d.namespace).toList();
    expect(namespaces.toSet(), hasLength(namespaces.length));
    for (final ns in namespaces) {
      expect(
        client.getField(Symbol(ns)).reflectee,
        same(client.getField(Symbol(ns)).reflectee),
      );
    }
  });
}
