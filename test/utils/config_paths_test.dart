import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteboat/utils/config_paths.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ConfigPaths', () {
    test('configFileName constant is correct', () {
      expect(ConfigPaths.configFileName, 'noteboat_config.yaml');
    });

    test('getConfigFilePath returns a path', () async {
      final configPath = await ConfigPaths.getConfigFilePath();

      expect(configPath, isNotEmpty);
      expect(configPath, endsWith(ConfigPaths.configFileName));
    });

    test('ensureConfigDirectoryExists creates directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('noteboat_test_');
      try {
        final configPath = path.join(tempDir.path, 'new', 'config', 'path', 'config.yaml');

        await ConfigPaths.ensureConfigDirectoryExists(configPath);

        final dir = Directory(path.join(tempDir.path, 'new', 'config', 'path'));
        expect(await dir.exists(), isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('ensureConfigDirectoryExists handles existing directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('noteboat_test_');
      try {
        final configDir = Directory(path.join(tempDir.path, 'existing', 'config'));
        await configDir.create(recursive: true);

        final configPath = path.join(configDir.path, 'config.yaml');

        // Should not throw when directory already exists
        await ConfigPaths.ensureConfigDirectoryExists(configPath);

        expect(await configDir.exists(), isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('getConfigFilePath is consistent across multiple calls', () async {
      final path1 = await ConfigPaths.getConfigFilePath();
      final path2 = await ConfigPaths.getConfigFilePath();

      expect(path1, equals(path2));
    });
  });
}
