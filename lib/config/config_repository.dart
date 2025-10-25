import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import '../utils/config_paths.dart';
import 'app_config.dart';

/// Shared configuration repository (pure Dart, no Flutter dependencies)
/// Handles loading and saving configuration for both GUI and CLI
class ConfigRepository {
  AppConfig? _cachedConfig;

  /// Check if we're on web by trying to access Platform
  static bool _isWeb() {
    try {
      // Try to access Platform.environment - this will throw on web
      // ignore: unnecessary_statements
      Platform.environment;
      return false;
    } on UnsupportedError {
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get home directory in a web-safe way
  static String? _getHomeDirectory() {
    if (_isWeb()) {
      // On web, there's no home directory - use a default path
      return '/noteboat';
    }
    return Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  }

  /// Expand tilde (~) in paths to the actual home directory
  static String expandPath(String pathStr) {
    if (pathStr.startsWith('~/')) {
      final home = _getHomeDirectory();
      if (home != null) {
        return pathStr.replaceFirst('~', home);
      }
    }
    return pathStr;
  }

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
      final configMap = Map<String, dynamic>.from(yaml);

      // Expand tildes in directory paths
      if (configMap['directories'] is List) {
        configMap['directories'] = (configMap['directories'] as List)
            .map((dir) => expandPath(dir.toString()))
            .toList();
      }

      _cachedConfig = AppConfig.fromMap(configMap);
    } else {
      // Create default config
      _cachedConfig = _createDefaultConfig();
      await saveConfig(_cachedConfig!);
    }

    return _cachedConfig!;
  }

  /// Validate a directory path - checks if it exists and is accessible
  /// Returns null if valid, error message if invalid
  Future<String?> validateDirectory(String dirPath) async {
    try {
      // On web, directories are virtual - always valid
      if (_isWeb()) {
        return null; // Web uses browser storage, no validation needed
      }

      // Expand tilde in path
      final expandedPath = expandPath(dirPath);
      final dir = Directory(expandedPath);

      // Check if directory exists
      if (!await dir.exists()) {
        // Try to create it
        try {
          await dir.create(recursive: true);
          return null; // Successfully created
        } catch (e) {
          return 'Cannot create directory: ${e.toString()}';
        }
      }

      // Directory exists, check if we can write to it
      try {
        final testFile = File(path.join(expandedPath, '.noteboat_test'));
        await testFile.writeAsString('test');
        await testFile.delete();
        return null; // Directory is writable
      } catch (e) {
        return 'Directory is not writable: ${e.toString()}';
      }
    } catch (e) {
      return 'Invalid directory path: ${e.toString()}';
    }
  }

  /// Validate all directories in the config
  /// Returns a map of directory path -> error message (null if valid)
  Future<Map<String, String?>> validateAllDirectories() async {
    final config = await loadConfig();
    final results = <String, String?>{};

    for (final dir in config.directories) {
      results[dir] = await validateDirectory(dir);
    }

    return results;
  }

  /// Check if at least one valid directory exists in the config
  Future<bool> hasValidDirectory() async {
    final validation = await validateAllDirectories();
    return validation.values.any((error) => error == null);
  }

  /// Get list of valid directories only
  Future<List<String>> getValidDirectories() async {
    final validation = await validateAllDirectories();
    return validation.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();
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
    final home = _getHomeDirectory();
    if (home == null) {
      throw Exception('Could not determine home directory');
    }

    // Use consistent default directory across CLI and GUI
    String defaultNotesDir;
    if (_isWeb()) {
      // On web, use a virtual path (browser storage)
      defaultNotesDir = '/noteboat/notes';
    } else if (Platform.isLinux || Platform.isMacOS) {
      defaultNotesDir = path.join(home, 'noteboat', 'notes');
    } else if (Platform.isWindows) {
      defaultNotesDir = path.join(home, 'Documents', 'noteboat', 'notes');
    } else {
      defaultNotesDir = path.join(home, 'noteboat', 'notes');
    }

    // Create default notes directory if it doesn't exist (not on web)
    if (!_isWeb()) {
      final dir = Directory(defaultNotesDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
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
