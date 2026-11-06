@TestOn('vm')
library;

import 'dart:io';

import 'package:roxyapi/roxyapi.dart';
import 'package:roxyapi/src/version.dart';
import 'package:test/test.dart';

import '../tool/docs.dart';
import 'spec_fixture.dart';

void main() {
  final codes = [for (final c in committedApi.errorCodes) c.code];

  test('ErrorCodes holds exactly the spec codes, in spec order', () {
    expect(ErrorCodes.all, codes);
    expect(ErrorCodes.rateLimitPerMinute, 'rate_limit_per_minute');
  });

  for (final path in [readmePath, agentsPath, llmsPath]) {
    test('$path lists exactly the spec error codes in spec order', () {
      final errors = region(File(path).readAsStringSync(), 'ERRORS') ?? '';
      final listed = RegExp(
        r'^\| (?:\d+|Any) \| `([^`]+)` \|',
        multiLine: true,
      ).allMatches(errors).map((m) => m[1]);
      expect(listed, codes);
    });
  }

  final docs = {
    for (final path in [readmePath, agentsPath])
      path: File(path).readAsStringSync(),
  };

  test(
    'every docs code block of the examples is the compiled example source',
    () {
      final examples = exampleRegions();
      final shown = <String>{};
      for (final MapEntry(key: path, value: text) in docs.entries) {
        for (final name in exampleRegionNames(text)) {
          shown.add(name);
          expect(
            region(text, 'EXAMPLE:$name'),
            '```dart\n${examples[name]}\n```',
            reason: '$path $name',
          );
        }
      }
      expect(shown, examples.keys.toSet());
    },
  );

  test('every call the docs name is a real method with real arguments', () {
    final params = {
      for (final d in committedApi.domains)
        for (final op in d.operations)
          'roxy.${d.namespace}.${op.operationId}': {
            for (final p in op.params) p.dart,
          },
    };
    for (final MapEntry(key: path, value: text) in docs.entries) {
      for (final call in RegExp(r'(roxy\.[a-z]\w*\.\w+)\(').allMatches(text)) {
        final name = call[1] ?? '';
        expect(params, contains(name), reason: '$path names $name');
        for (final arg in topLevelArguments(text, call.end)) {
          expect(params[name], contains(arg), reason: '$path: $name($arg:)');
        }
      }
    }
  });

  test(
    'the Flutter example loads one @roxyapi/ui script, pinned to a major',
    () {
      final cdn = RegExp(
        r'https://cdn\.jsdelivr\.net/npm/@roxyapi/ui@[^/]+/dist/cdn/roxy-ui\.js',
      );
      final urls = {
        for (final path in [
          'example/flutter_app/web/index.html',
          'example/flutter_app/lib/natal_chart_view_mobile.dart',
        ])
          ...cdn.allMatches(File(path).readAsStringSync()).map((m) => m[0]),
      };
      expect(urls, {
        'https://cdn.jsdelivr.net/npm/@roxyapi/ui@1/dist/cdn/roxy-ui.js',
      });
    },
  );

  test('the package version is one value', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(r'^version: (\S+)$', multiLine: true).firstMatch(pubspec)?[1],
      version,
    );
  });
}

/// The named arguments at the top level of the call whose `(` ends before [start], skipping
/// string literals.
Iterable<String> topLevelArguments(String text, int start) sync* {
  var depth = 1;
  for (var i = start; i < text.length && depth > 0; i++) {
    final char = text[i];
    switch (char) {
      case "'" || '"':
        i = text.indexOf(char, i + 1);
        if (i < 0) return;
      case '(' || '[' || '{':
        depth++;
      case ')' || ']' || '}':
        depth--;
      case _ when depth == 1 && !RegExp(r'[\w.$]').hasMatch(text[i - 1]):
        final arg = RegExp(r'(\w+):(?!:)').matchAsPrefix(text, i);
        if (arg != null) yield arg[1] ?? '';
    }
  }
}
