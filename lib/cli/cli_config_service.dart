import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import '../utils/config_paths.dart';

/// Pure Dart configuration service for CLI (no Flutter dependencies)
/// Simplified version that only handles what CLI needs
class CliConfigService {
  Future<List<String>> getNotesDirectories() async {
    try {
      final configFilePath = await ConfigPaths.getConfigFilePath();
      final configFile = File(configFilePath);

      if (!await configFile.exists()) {
        // Return default directories if config doesn't exist
        return _getDefaultDirectories();
      }

      final content = await configFile.readAsString();
      final yaml = loadYaml(content);

      if (yaml is! Map) {
        return _getDefaultDirectories();
      }

      final dirs = yaml['directories'];
      if (dirs is List) {
        return dirs.map((d) => d.toString()).toList();
      }

      return _getDefaultDirectories();
    } catch (e) {
      // If any error, return default directories
      return _getDefaultDirectories();
    }
  }

  List<String> _getDefaultDirectories() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      return [];
    }

    if (Platform.isLinux || Platform.isMacOS) {
      return [path.join(home, 'notes')];
    } else if (Platform.isWindows) {
      return [path.join(home, 'Documents', 'notes')];
    }

    return [path.join(home, 'notes')];
  }
}
