import 'config_service.dart';
import 'note_service.dart';
import 'note_service_interface.dart';

ConfigService? _sharedConfigService;

/// Desktop implementation - uses NoteService with direct file I/O
INoteService createNoteServiceImpl() {
  _sharedConfigService ??= ConfigService();
  return NoteService(_sharedConfigService!);
}

/// Desktop uses local config
ConfigService createConfigServiceImpl() {
  _sharedConfigService ??= ConfigService();
  return _sharedConfigService!;
}
