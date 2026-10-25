import 'dart:convert';
import 'dart:io';

/// Real responses captured from the API (see docs/api.md).
Object? fixture(String name) =>
    jsonDecode(File('test/fixtures/api/$name.json').readAsStringSync());

Map<String, Object?> fixtureMap(String name) =>
    Map<String, Object?>.from(fixture(name)! as Map);

List<Map<String, Object?>> fixtureList(String name) => [
  for (final e in fixture(name)! as List) Map<String, Object?>.from(e as Map),
];
