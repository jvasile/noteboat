import 'dart:io';
import 'package:path/path.dart' as path;

/// Shared utility for finding config file paths
/// This is pure Dart with no Flutter dependencies so both CLI and GUI can use it
class ConfigPaths {
  static const String configFileName = 'noteboat_config.yaml';

  /// Get all possible config file locations in order of preference
  /// Returns the first one that exists, or the primary location if none exist
  static Future<String> getConfigFilePath() async {
    final candidates = _getConfigCandidates();

    // Return first existing config file
    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }

    // If no config exists, return the primary location (first candidate)
    // The caller will create it there
    return candidates.first;
  }

  /// Get all possible config file locations in order of preference
  static List<String> _getConfigCandidates() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      throw Exception('Could not determine home directory');
    }

    final candidates = <String>[];

    // 1. ~/noteboat/noteboat_config.yaml (legacy/custom location)
    candidates.add(path.join(home, 'noteboat', configFileName));

    // 2. ~/.config/noteboat/config.yaml (XDG standard on Linux)
    if (Platform.isLinux) {
      final xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
      if (xdgConfig != null && xdgConfig.isNotEmpty) {
        candidates.add(path.join(xdgConfig, 'noteboat', 'config.yaml'));
      } else {
        candidates.add(path.join(home, '.config', 'noteboat', 'config.yaml'));
      }
    }

    // 3. ~/Documents/noteboat/noteboat_config.yaml (Flutter's getApplicationDocumentsDirectory default on Linux)
    if (Platform.isLinux || Platform.isMacOS) {
      candidates.add(path.join(home, 'Documents', 'noteboat', configFileName));
    }

    // 4. ~/Library/Application Support/com.example.noteboat/noteboat_config.yaml (macOS)
    if (Platform.isMacOS) {
      candidates.add(path.join(home, 'Library', 'Application Support', 'com.example.noteboat', configFileName));
    }

    // 5. %APPDATA%/noteboat/noteboat_config.yaml (Windows)
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        candidates.add(path.join(appData, 'noteboat', configFileName));
      } else {
        candidates.add(path.join(home, 'AppData', 'Roaming', 'noteboat', configFileName));
      }
    }

    return candidates;
  }

  /// Ensure the config directory exists
  static Future<void> ensureConfigDirectoryExists(String configFilePath) async {
    final dir = Directory(path.dirname(configFilePath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
