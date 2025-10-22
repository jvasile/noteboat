import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteboat/config/config_repository.dart';
import 'package:noteboat/config/app_config.dart';

void main() {
  group('ConfigRepository', () {
    test('loads config successfully', () async {
      final repository = ConfigRepository();

      final config = await repository.loadConfig();

      expect(config.directories, isNotEmpty);
      expect(config.themeMode, isNotEmpty);
      expect(config.baseFontSize, greaterThan(0));
      expect(config.editorMode, isIn(['basic', 'nvim']));
    });

    test('caches config after first load', () async {
      final repository = ConfigRepository();

      final config1 = await repository.loadConfig();
      final config2 = await repository.loadConfig();

      expect(identical(config1, config2), isTrue);
    });

    test('clearCache forces reload', () async {
      final repository = ConfigRepository();

      final config1 = await repository.loadConfig();
      repository.clearCache();
      final config2 = await repository.loadConfig();

      // Should be different instances after clearCache
      expect(identical(config1, config2), isFalse);
    });

    test('getAllDirectories returns list', () async {
      final repository = ConfigRepository();

      final directories = await repository.getAllDirectories();

      expect(directories, isA<List<String>>());
      expect(directories, isNotEmpty);
    });

    test('getWriteDirectory returns first directory', () async {
      final repository = ConfigRepository();

      final writeDir = await repository.getWriteDirectory();

      expect(writeDir, isNotEmpty);

      final allDirs = await repository.getAllDirectories();
      expect(writeDir, allDirs.first);
    });

    test('saveConfig updates cached config', () async {
      final repository = ConfigRepository();

      final originalConfig = await repository.loadConfig();

      final newConfig = AppConfig(
        directories: ['/test/path'],
        themeMode: 'dark',
      );

      await repository.saveConfig(newConfig);

      final loadedConfig = await repository.loadConfig();

      // Should return the saved config
      expect(identical(loadedConfig, newConfig), isTrue);
    });

    test('round-trip save and load with clearCache', () async {
      final repository = ConfigRepository();

      final testConfig = AppConfig(
        directories: ['/path/one', '/path/two'],
        defaultEditor: 'vim',
        themeMode: 'dark',
        baseFontSize: 18.0,
        editorMode: 'nvim',
        nvimFontSize: 14.0,
        hotkeys: const HotkeyConfig(search: 'f'),
      );

      await repository.saveConfig(testConfig);
      repository.clearCache();

      final loadedConfig = await repository.loadConfig();

      expect(loadedConfig.directories, testConfig.directories);
      expect(loadedConfig.defaultEditor, testConfig.defaultEditor);
      expect(loadedConfig.themeMode, testConfig.themeMode);
      expect(loadedConfig.baseFontSize, testConfig.baseFontSize);
      expect(loadedConfig.editorMode, testConfig.editorMode);
      expect(loadedConfig.nvimFontSize, testConfig.nvimFontSize);
      expect(loadedConfig.hotkeys.search, testConfig.hotkeys.search);
    });
  });
}
