import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

/// Hotkey configuration for the application
class HotkeyConfig {
  final String newNote;
  final String search;
  final String editNote;
  final String viewMode;
  final String navigateBack;
  final String moveUp;
  final String moveDown;
  final String closeDialog;

  const HotkeyConfig({
    this.newNote = '+,Add',
    this.search = '/',
    this.editNote = 'e',
    this.viewMode = 'v',
    this.navigateBack = 'Escape,Alt+ArrowLeft',
    this.moveUp = 'ArrowUp,k',
    this.moveDown = 'ArrowDown,j',
    this.closeDialog = 'Escape',
  });

  factory HotkeyConfig.fromMap(Map<String, dynamic> map) {
    return HotkeyConfig(
      newNote: map['newNote']?.toString() ?? '+,Add',
      search: map['search']?.toString() ?? '/',
      editNote: map['editNote']?.toString() ?? 'e',
      viewMode: map['viewMode']?.toString() ?? 'v',
      navigateBack: map['navigateBack']?.toString() ?? 'Escape,Alt+ArrowLeft',
      moveUp: map['moveUp']?.toString() ?? 'ArrowUp,k',
      moveDown: map['moveDown']?.toString() ?? 'ArrowDown,j',
      closeDialog: map['closeDialog']?.toString() ?? 'Escape',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'newNote': newNote,
      'search': search,
      'editNote': editNote,
      'viewMode': viewMode,
      'navigateBack': navigateBack,
      'moveUp': moveUp,
      'moveDown': moveDown,
      'closeDialog': closeDialog,
    };
  }
}

class AppConfig {
  final List<String> directories;
  final String defaultEditor;
  final String themeMode; // 'light', 'dark', or 'system'
  final double baseFontSize; // Base font size for markdown content
  final HotkeyConfig hotkeys;

  AppConfig({
    required this.directories,
    this.defaultEditor = '',
    this.themeMode = 'system',
    this.baseFontSize = 16.0,
    this.hotkeys = const HotkeyConfig(),
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    // Handle both 'defaultEditor' and old 'defaultAuthor' for backward compatibility
    String editor = '';
    if (map['defaultEditor'] != null) {
      editor = map['defaultEditor']?.toString() ?? '';
    } else if (map['defaultAuthor'] != null) {
      editor = map['defaultAuthor']?.toString() ?? '';
    }

    // Parse font size, default to 16.0
    double fontSize = 16.0;
    if (map['baseFontSize'] != null) {
      final fontSizeValue = map['baseFontSize'];
      if (fontSizeValue is num) {
        fontSize = fontSizeValue.toDouble();
      }
    }

    // Parse hotkeys if present
    HotkeyConfig hotkeys = const HotkeyConfig();
    if (map['hotkeys'] != null && map['hotkeys'] is Map) {
      hotkeys = HotkeyConfig.fromMap(Map<String, dynamic>.from(map['hotkeys']));
    }

    return AppConfig(
      directories: (map['directories'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      defaultEditor: editor,
      themeMode: map['themeMode']?.toString() ?? 'system',
      baseFontSize: fontSize,
      hotkeys: hotkeys,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'directories': directories,
      'defaultEditor': defaultEditor,
      'themeMode': themeMode,
      'baseFontSize': baseFontSize,
      'hotkeys': hotkeys.toMap(),
    };
  }
}

class ConfigService {
  static const String _configFileName = 'noteboat_config.yaml';
  AppConfig? _config;

  Future<String> _getConfigPath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String configDir = path.join(appDocDir.path, 'noteboat');

    // Create config directory if it doesn't exist
    final dir = Directory(configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return path.join(configDir, _configFileName);
  }

  Future<AppConfig> loadConfig() async {
    if (_config != null) {
      return _config!;
    }

    final configPath = await _getConfigPath();
    final configFile = File(configPath);

    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      final yaml = loadYaml(content);
      _config = AppConfig.fromMap(Map<String, dynamic>.from(yaml));
    } else {
      // Create default config with a default notes directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String defaultNotesDir = path.join(appDocDir.path, 'noteboat', 'notes');

      // Create default notes directory
      final dir = Directory(defaultNotesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      _config = AppConfig(
        directories: [defaultNotesDir],
        defaultEditor: '',
        themeMode: 'system',
        baseFontSize: 16.0,
        hotkeys: const HotkeyConfig(),
      );

      await saveConfig(_config!);
    }

    return _config!;
  }

  Future<void> saveConfig(AppConfig config) async {
    _config = config;
    final configPath = await _getConfigPath();
    final configFile = File(configPath);

    final editorValue = config.defaultEditor.isEmpty
        ? '""'
        : config.defaultEditor;

    final yamlContent = '''# Noteboat Configuration
directories:
${config.directories.map((d) => '  - $d').join('\n')}
defaultEditor: $editorValue
themeMode: ${config.themeMode}
baseFontSize: ${config.baseFontSize}
hotkeys:
  newNote: ${config.hotkeys.newNote}
  search: ${config.hotkeys.search}
  editNote: ${config.hotkeys.editNote}
  viewMode: ${config.hotkeys.viewMode}
  navigateBack: ${config.hotkeys.navigateBack}
  moveUp: ${config.hotkeys.moveUp}
  moveDown: ${config.hotkeys.moveDown}
  closeDialog: ${config.hotkeys.closeDialog}
''';

    await configFile.writeAsString(yamlContent);
  }

  Future<String> getWriteDirectory() async {
    final config = await loadConfig();
    return config.directories.first;
  }

  Future<List<String>> getAllDirectories() async {
    final config = await loadConfig();
    return config.directories;
  }
}
