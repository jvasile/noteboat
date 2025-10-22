import '../config/app_config.dart';
import '../config/config_repository.dart';

// Re-export for backward compatibility
export '../config/app_config.dart';

/// Configuration service for GUI (delegates to shared ConfigRepository)
/// This class maintained for backward compatibility with existing GUI code
class ConfigService {
  final ConfigRepository _repository = ConfigRepository();

  Future<AppConfig> loadConfig() async {
    return _repository.loadConfig();
  }

  Future<void> saveConfig(AppConfig config) async {
    return _repository.saveConfig(config);
  }

  Future<String> getWriteDirectory() async {
    return _repository.getWriteDirectory();
  }

  Future<List<String>> getAllDirectories() async {
    return _repository.getAllDirectories();
  }
}
