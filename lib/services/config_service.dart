import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

class AppConfig {
  final List<String> directories;
  final String defaultEditor;
  final String themeMode; // 'light', 'dark', or 'system'
  final double baseFontSize; // Base font size for markdown content

  AppConfig({
    required this.directories,
    this.defaultEditor = '',
    this.themeMode = 'system',
    this.baseFontSize = 16.0,
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

    return AppConfig(
      directories: (map['directories'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      defaultEditor: editor,
      themeMode: map['themeMode']?.toString() ?? 'system',
      baseFontSize: fontSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'directories': directories,
      'defaultEditor': defaultEditor,
      'themeMode': themeMode,
      'baseFontSize': baseFontSize,
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
