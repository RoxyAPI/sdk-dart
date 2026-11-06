/// Rewrites the generated regions of README.md, AGENTS.md and doc/llms-full.txt. Prose outside
/// the `<!-- BEGIN:X -->` / `<!-- END:X -->` markers is hand-written and survives every run.
library;

import 'dart:io';

import 'emit.dart';
import 'spec.dart';

const readmePath = 'README.md';
const agentsPath = 'AGENTS.md';
const llmsPath = 'doc/llms-full.txt';
const exampleDir = 'example';

/// Replaces the body of region [name] in [source]; fails when the markers are missing.
String replaceRegion(String source, String name, String block, String path) {
  final begin = '<!-- BEGIN:$name -->';
  final end = '<!-- END:$name -->';
  final from = source.indexOf(begin);
  final to = source.indexOf(end);
  if (from == -1 || to < from) fail('$path is missing $begin / $end');
  return '${source.substring(0, from)}$begin\n${block.trim()}\n${source.substring(to)}';
}

/// The body of region [name] in [source], or `null` when it has none.
String? region(String source, String name) {
  final begin = '<!-- BEGIN:$name -->';
  final from = source.indexOf(begin);
  final to = source.indexOf('<!-- END:$name -->');
  return from == -1 || to < from
      ? null
      : source.substring(from + begin.length, to).trim();
}

String domainsTable(Api api) => [
  '| Namespace | What it covers |',
  '|-----------|----------------|',
  for (final d in api.domains)
    '| [`roxy.${d.namespace}`](${d.referenceUrl}) | ${d.summary} |',
].join('\n');

String errorsTable(Api api) => [
  'Every error returns `{ error, code, doc_url }`, thrown as `RoxyException` with `statusCode`, '
      '`code`, `message` and `docUrl`. Switch on `code`; `message` is readable text and may change. '
      'Each meaning below says whether and when to retry, and `retryAfter` carries the wait when '
      'the response sends it. Every code is documented at https://roxyapi.com/docs/errors.',
  '',
  '| Status | Code | Meaning |',
  '|--------|------|---------|',
  for (final c in api.errorCodes)
    '| ${c.status ?? 'Any'} | `${c.code}` | ${c.meaning} |',
].join('\n');

String langsNote(Api api) {
  final lang = api.langEnum;
  final defaults = <Object?>{};
  final supported = <String>{};
  for (final op in api.operations) {
    for (final p in op.params) {
      if (p.source == ParamSource.query && p.wire == 'lang') {
        supported.add(op.namespace);
        defaults.add(p.schema['default']);
      }
    }
  }
  if (defaults.length > 1) {
    fail('lang declares more than one default: $defaults');
  }
  final codes = lang.values.map((v) => '`$v`').join(', ');
  final names = [for (final d in api.domains) d.namespace];
  String list(Iterable<String> ns) => ns.map((n) => '`$n`').join(', ');
  return '**Multi-language responses.** Interpretations and editorial text are available in '
      '${lang.values.length} languages: $codes. Pass a `Lang` value as `lang` on a supported method. '
      'Supported: ${list(names.where(supported.contains))}. '
      'English-only: ${list(names.where((n) => !supported.contains(n)))}. A field without a '
      'translation in the requested language returns English.';
}

String methodSections(Api api) {
  final examples = Examples(api);
  return api.domains
      .map((d) {
        final calls = d.operations
            .map((op) {
              final comment = op.summary == null ? '' : '// ${op.summary}\n';
              return '${comment}final result = await ${examples.call(op)};\n'
                  '// ${returns(api, op.response)}';
            })
            .join('\n\n');
        return '## ${d.tag}: `roxy.${d.namespace}`\n\n${d.summary}\n\n'
            '[API reference](${d.referenceUrl})\n\n```dart\n$calls\n```';
      })
      .join('\n\n---\n\n');
}

/// `Returns X: field Type, ...` for a response: the top-level fields of its model, the names a
/// caller reads first. A list response names its element model.
String returns(Api api, TypeRef response) {
  final root = response is ListType ? response.item : response;
  if (root is! ModelType) return 'Returns ${typeCode(response)}';
  final model = api.models[root.name] ?? fail('unknown model ${root.name}');
  final fields = model.fields.map((f) {
    final t = f.types[Side.response] ?? fail('unreachable');
    return '${f.dart} ${typeCode(f.required ? t : t.withNullable(true))}';
  });
  return 'Returns ${typeCode(response)}: ${fields.join(', ')}';
}

/// Every `// #docregion name` ... `// #enddocregion name` block of the Dart files under
/// `example/`, dedented; a region opened again continues where it left off. The README copies
/// them, so every code block it shows compiles.
Map<String, String> exampleRegions() {
  final segments = <String, List<String>>{};
  final files =
      Directory(exampleDir)
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.contains('/.') &&
                !f.path.contains('/build/'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final open = <String, List<String>>{};
    for (final line in file.readAsLinesSync()) {
      final start = RegExp(r'^\s*// #docregion (\S+)$').firstMatch(line);
      final stop = RegExp(r'^\s*// #enddocregion (\S+)$').firstMatch(line);
      if (start != null) {
        open[start[1] ?? ''] = [];
      } else if (stop != null) {
        final name = stop[1] ?? '';
        final lines =
            open.remove(name) ??
            fail('${file.path}: #enddocregion $name without start');
        segments.putIfAbsent(name, () => []).add(_dedent(lines));
      } else {
        for (final lines in open.values) {
          lines.add(line);
        }
      }
    }
    if (open.isNotEmpty) fail('${file.path}: unclosed #docregion ${open.keys}');
  }
  return {
    for (final MapEntry(:key, :value) in segments.entries)
      key: value.join('\n').trim(),
  };
}

String _dedent(List<String> lines) {
  final indents = lines
      .where((l) => l.trim().isNotEmpty)
      .map((l) => l.length - l.trimLeft().length);
  final cut = indents.isEmpty ? 0 : indents.reduce((a, b) => a < b ? a : b);
  return lines
      .map((l) => l.length < cut ? l.trim() : l.substring(cut))
      .join('\n');
}

/// The names of the `EXAMPLE:name` regions [source] declares.
Iterable<String> exampleRegionNames(String source) => RegExp(
  '<!-- BEGIN:EXAMPLE:([a-z0-9-]+) -->',
).allMatches(source).map((m) => m[1] ?? '');

/// Rewrites every generated docs region; fails on a missing marker or an unknown example.
void syncDocs(Api api) {
  final examples = exampleRegions();
  final used = <String>{};
  void sync(String path, String Function(String source) edit) {
    final file = File(path);
    final before = file.readAsStringSync();
    final after = edit(before);
    if (after != before) file.writeAsStringSync(after);
  }

  String withExamples(String source, String path) {
    var out = source;
    for (final name in exampleRegionNames(source).toList()) {
      final code =
          examples[name] ??
          fail('$path asks for example region $name, none exists');
      used.add(name);
      out = replaceRegion(out, 'EXAMPLE:$name', '```dart\n$code\n```', path);
    }
    return out;
  }

  sync(readmePath, (source) {
    var out = withExamples(source, readmePath);
    out = replaceRegion(out, 'DOMAINS', domainsTable(api), readmePath);
    out = replaceRegion(out, 'LANGS', langsNote(api), readmePath);
    return replaceRegion(out, 'ERRORS', errorsTable(api), readmePath);
  });
  sync(agentsPath, (source) {
    var out = withExamples(source, agentsPath);
    out = replaceRegion(out, 'DOMAINS', domainsTable(api), agentsPath);
    return replaceRegion(out, 'ERRORS', errorsTable(api), agentsPath);
  });
  final unused = examples.keys.toSet().difference(used);
  if (unused.isNotEmpty) {
    fail('example regions shown in neither README nor AGENTS: $unused');
  }
  sync(llmsPath, (source) {
    var out = replaceRegion(source, 'LANGS', langsNote(api), llmsPath);
    out = replaceRegion(out, 'METHODS', methodSections(api), llmsPath);
    out = replaceRegion(out, 'ERRORS', errorsTable(api), llmsPath);
    return out;
  });
}
