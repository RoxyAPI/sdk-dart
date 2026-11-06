import 'dart:convert';
import 'dart:io';

import '../tool/spec.dart';

/// The committed spec, read through the generator model: the only list the tests check the
/// SDK surface against.
final Api committedApi = Api.read(
  asJson(jsonDecode(File('specs/openapi.json').readAsStringSync()), 'spec'),
);
