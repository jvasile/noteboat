import 'package:yaml/yaml.dart';

void main() {
  final yamlStr = '''
"@id": c9b91f06-671e-420e-be6b-b1f432a1a3d8
title: CamelCase
mtime: 2025-10-21T09:12:43.790403
author: []
"@type":
  - note
_links:
  - CamelCase
_tags:
  - CamelCase
''';

  try {
    final result = loadYaml(yamlStr);
    print('SUCCESS!');
    print(result);
  } catch (e) {
    print('FAILED!');
    print(e);
  }
}
