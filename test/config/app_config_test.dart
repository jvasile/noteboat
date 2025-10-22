import 'package:flutter_test/flutter_test.dart';
import 'package:noteboat/config/app_config.dart';

void main() {
  group('HotkeyConfig', () {
    test('creates with default values', () {
      const config = HotkeyConfig();

      expect(config.newNote, '+,Add');
      expect(config.search, '/');
      expect(config.editNote, 'e');
      expect(config.viewMode, 'v');
      expect(config.navigateBack, 'Escape,Alt+ArrowLeft');
      expect(config.moveUp, 'ArrowUp,k');
      expect(config.moveDown, 'ArrowDown,j');
      expect(config.closeDialog, 'Escape');
    });

    test('creates from map with all values', () {
      final map = {
        'newNote': 'n',
        'search': 's',
        'editNote': 'e',
        'viewMode': 'v',
        'navigateBack': 'Escape',
        'moveUp': 'k',
        'moveDown': 'j',
        'closeDialog': 'q',
      };

      final config = HotkeyConfig.fromMap(map);

      expect(config.newNote, 'n');
      expect(config.search, 's');
      expect(config.editNote, 'e');
      expect(config.viewMode, 'v');
      expect(config.navigateBack, 'Escape');
      expect(config.moveUp, 'k');
      expect(config.moveDown, 'j');
      expect(config.closeDialog, 'q');
    });

    test('creates from map with missing values uses defaults', () {
      final map = <String, dynamic>{};

      final config = HotkeyConfig.fromMap(map);

      expect(config.newNote, '+,Add');
      expect(config.search, '/');
      expect(config.editNote, 'e');
    });

    test('serializes to map correctly', () {
      const config = HotkeyConfig(
        newNote: 'n',
        search: 's',
      );

      final map = config.toMap();

      expect(map['newNote'], 'n');
      expect(map['search'], 's');
      expect(map['editNote'], 'e'); // default
    });
  });

  group('AppConfig', () {
    test('creates with required directories', () {
      final config = AppConfig(
        directories: ['/home/user/notes'],
      );

      expect(config.directories, ['/home/user/notes']);
      expect(config.defaultEditor, '');
      expect(config.themeMode, 'system');
      expect(config.baseFontSize, 16.0);
      expect(config.editorMode, 'basic');
      expect(config.nvimFontSize, 16.0);
    });

    test('creates from map with all values', () {
      final map = {
        'directories': ['/home/user/notes', '/home/user/docs'],
        'defaultEditor': 'vim',
        'themeMode': 'dark',
        'baseFontSize': 18.0,
        'editorMode': 'nvim',
        'nvimFontSize': 14.0,
        'hotkeys': {
          'newNote': 'n',
          'search': 's',
        },
      };

      final config = AppConfig.fromMap(map);

      expect(config.directories, ['/home/user/notes', '/home/user/docs']);
      expect(config.defaultEditor, 'vim');
      expect(config.themeMode, 'dark');
      expect(config.baseFontSize, 18.0);
      expect(config.editorMode, 'nvim');
      expect(config.nvimFontSize, 14.0);
      expect(config.hotkeys.newNote, 'n');
      expect(config.hotkeys.search, 's');
    });

    test('handles legacy defaultAuthor field', () {
      final map = {
        'directories': ['/home/user/notes'],
        'defaultAuthor': 'John Doe',
      };

      final config = AppConfig.fromMap(map);

      expect(config.defaultEditor, 'John Doe');
    });

    test('prefers defaultEditor over defaultAuthor', () {
      final map = {
        'directories': ['/home/user/notes'],
        'defaultEditor': 'Jane Doe',
        'defaultAuthor': 'John Doe',
      };

      final config = AppConfig.fromMap(map);

      expect(config.defaultEditor, 'Jane Doe');
    });

    test('validates editorMode to basic or nvim', () {
      final map = {
        'directories': ['/home/user/notes'],
        'editorMode': 'invalid',
      };

      final config = AppConfig.fromMap(map);

      expect(config.editorMode, 'basic'); // falls back to basic
    });

    test('handles missing directories as empty list', () {
      final map = <String, dynamic>{};

      final config = AppConfig.fromMap(map);

      expect(config.directories, []);
    });

    test('serializes to map correctly', () {
      final config = AppConfig(
        directories: ['/home/user/notes'],
        defaultEditor: 'vim',
        themeMode: 'dark',
        baseFontSize: 18.0,
        editorMode: 'nvim',
        nvimFontSize: 14.0,
        hotkeys: const HotkeyConfig(newNote: 'n'),
      );

      final map = config.toMap();

      expect(map['directories'], ['/home/user/notes']);
      expect(map['defaultEditor'], 'vim');
      expect(map['themeMode'], 'dark');
      expect(map['baseFontSize'], 18.0);
      expect(map['editorMode'], 'nvim');
      expect(map['nvimFontSize'], 14.0);
      expect(map['hotkeys']['newNote'], 'n');
    });

    test('round-trip serialization preserves data', () {
      final original = AppConfig(
        directories: ['/home/user/notes', '/home/user/docs'],
        defaultEditor: 'emacs',
        themeMode: 'light',
        baseFontSize: 20.0,
        editorMode: 'nvim',
        nvimFontSize: 16.0,
        hotkeys: const HotkeyConfig(search: 'f'),
      );

      final map = original.toMap();
      final restored = AppConfig.fromMap(map);

      expect(restored.directories, original.directories);
      expect(restored.defaultEditor, original.defaultEditor);
      expect(restored.themeMode, original.themeMode);
      expect(restored.baseFontSize, original.baseFontSize);
      expect(restored.editorMode, original.editorMode);
      expect(restored.nvimFontSize, original.nvimFontSize);
      expect(restored.hotkeys.search, original.hotkeys.search);
    });
  });
}
