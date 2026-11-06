/// The SDK namespace of an operation: the first segment of its URL path in lowerCamelCase.
///
/// `/vedic-astrology/birth-chart` is `vedicAstrology`, `/crystals/{id}` is `crystals`. The
/// generator, the docs sync and the tests all derive it here, so a new domain in the spec needs
/// no configuration anywhere in this repository.
String pathNamespace(String path) {
  final segment = path
      .split('/')
      .firstWhere((s) => s.isNotEmpty, orElse: () => '');
  if (segment.isEmpty || segment.startsWith('{')) {
    throw StateError('cannot derive a namespace from path "$path"');
  }
  return segment.replaceAllMapped(
    RegExp('-([a-z0-9])'),
    (m) => (m[1] ?? '').toUpperCase(),
  );
}
