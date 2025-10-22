import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import '../utils/config_paths.dart';
import 'app_config.dart';

/// Shared configuration repository (pure Dart, no Flutter dependencies)
/// Handles loading and saving configuration for both GUI and CLI
class ConfigRepository {
  AppConfig? _cachedConfig;

  /// Load configuration from file, or create default if doesn't exist
  Future<AppConfig> loadConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    final configPath = await ConfigPaths.getConfigFilePath();
    final configFile = File(configPath);

    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      final yaml = loadYaml(content);
      _cachedConfig = AppConfig.fromMap(Map<String, dynamic>.from(yaml));
    } else {
      // Create default config
      _cachedConfig = _createDefaultConfig();
      await saveConfig(_cachedConfig!);
    }

    return _cachedConfig!;
  }

  /// Save configuration to file
  Future<void> saveConfig(AppConfig config) async {
    _cachedConfig = config;
    final configPath = await ConfigPaths.getConfigFilePath();
    await ConfigPaths.ensureConfigDirectoryExists(configPath);

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
editorMode: ${config.editorMode}
nvimFontSize: ${config.nvimFontSize}
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

  /// Get all configured note directories
  Future<List<String>> getAllDirectories() async {
    final config = await loadConfig();
    return config.directories;
  }

  /// Get the first directory (used for writing new notes)
  Future<String> getWriteDirectory() async {
    final config = await loadConfig();
    return config.directories.first;
  }

  /// Clear cached config (forces reload on next access)
  void clearCache() {
    _cachedConfig = null;
  }

  /// Create default configuration with platform-appropriate defaults
  AppConfig _createDefaultConfig() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      throw Exception('Could not determine home directory');
    }

    // Use consistent default directory across CLI and GUI
    String defaultNotesDir;
    if (Platform.isLinux || Platform.isMacOS) {
      defaultNotesDir = path.join(home, 'noteboat', 'notes');
    } else if (Platform.isWindows) {
      defaultNotesDir = path.join(home, 'Documents', 'noteboat', 'notes');
    } else {
      defaultNotesDir = path.join(home, 'noteboat', 'notes');
    }

    // Create default notes directory if it doesn't exist
    final dir = Directory(defaultNotesDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return AppConfig(
      directories: [defaultNotesDir],
      defaultEditor: '',
      themeMode: 'system',
      baseFontSize: 16.0,
      hotkeys: const HotkeyConfig(),
      editorMode: 'basic',
      nvimFontSize: 16.0,
    );
  }
}
