/// The one entry point for CI, the hooks and the release: load the spec, normalize it into
/// `specs/openapi.json`, emit `lib/src/*.g.dart` and `test/calls.g.dart`, sync the docs
/// regions and format the output. Rerun from the committed spec, it rewrites nothing.
///
/// `ROXYAPI_SPEC_FILE=specs/openapi.json dart run tool/generate.dart` reads the spec from disk;
/// without it the live spec is fetched.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'docs.dart';
import 'emit.dart';
import 'spec.dart';

const specUrl = 'https://roxyapi.com/api/v2/openapi.json';
const specPath = 'specs/openapi.json';
const origin = 'https://roxyapi.com';

Future<void> main() async {
  final spec = asJson(jsonDecode(await _loadSpec()), 'spec');
  _absoluteServer(spec);
  _write(specPath, const JsonEncoder.withIndent('  ').convert(spec));

  final api = Api.read(spec);
  final outputs = {
    'lib/src/enums.g.dart': enumsLibrary(api),
    'lib/src/models.g.dart': modelsLibrary(api),
    'lib/src/api.g.dart': apiLibrary(api),
    'lib/src/error_codes.g.dart': errorCodesLibrary(api),
    'test/calls.g.dart': callsLibrary(api),
  };
  for (final MapEntry(key: path, value: source) in outputs.entries) {
    _write(path, source);
  }
  final format = await Process.run('dart', ['format', ...outputs.keys]);
  if (format.exitCode != 0) {
    fail('dart format failed:\n${format.stdout}${format.stderr}');
  }
  syncDocs(api);
  stdout.writeln(
    'generate: ${api.domains.length} domains, ${api.operations.length} operations, '
    '${api.models.length} models, ${api.enums.length} enums, ${api.errorCodes.length} error codes',
  );
}

/// The spec from `ROXYAPI_SPEC_FILE`, else the live spec, retried so a transient upstream error
/// does not fail the daily release.
Future<String> _loadSpec() async {
  final file = Platform.environment['ROXYAPI_SPEC_FILE'];
  if (file != null && file.isNotEmpty) return File(file).readAsString();
  for (var attempt = 1; ; attempt++) {
    try {
      final response = await http.get(
        Uri.parse(specUrl),
        headers: {'Cache-Control': 'no-cache'},
      );
      if (response.statusCode != 200) {
        throw HttpException('spec fetch returned ${response.statusCode}');
      }
      return utf8.decode(response.bodyBytes);
    } on Exception catch (error) {
      if (attempt == 5) rethrow;
      stderr.writeln('spec fetch attempt $attempt failed ($error), retrying');
      await Future<void>.delayed(Duration(seconds: 1 << attempt));
    }
  }
}

/// A relative `servers[0].url` is made absolute, so the client needs no base URL setting.
void _absoluteServer(Json spec) {
  final servers = asJsonList(spec['servers'], 'servers');
  final server = asJson(servers.first, 'servers[0]');
  final url = asText(server['url']) ?? fail('servers[0].url is missing');
  if (url.startsWith('/')) server['url'] = '$origin$url';
}

void _write(String path, String content) {
  final file = File(path);
  if (!file.existsSync() || file.readAsStringSync() != content) {
    file
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
}
