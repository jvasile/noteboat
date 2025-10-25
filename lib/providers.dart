import 'package:riverpod/riverpod.dart';
import 'services/config_service.dart';
import 'services/note_service_interface.dart';
import 'services/note_service_factory.dart';

/// Provider for ConfigService
/// On desktop: Uses local file-based configuration
/// On web: Returns stub ConfigService (config is server-side)
final configServiceProvider = Provider<ConfigService>((ref) {
  return NoteServiceFactory.createConfigService();
});

/// Provider for NoteService
/// On desktop: Uses NoteService with direct file I/O
/// On web: Uses NoteServiceHttp that communicates with server via HTTP
final noteServiceProvider = Provider<INoteService>((ref) {
  return NoteServiceFactory.createNoteService();
});
