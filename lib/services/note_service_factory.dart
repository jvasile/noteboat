import 'config_service.dart';
import 'note_service_interface.dart';
import 'note_service_factory_impl.dart'
    if (dart.library.html) 'note_service_factory_web.dart';

/// Factory to create the appropriate note service implementation
/// Uses NoteService on desktop, NoteServiceHttp on web
class NoteServiceFactory {
  static INoteService createNoteService() {
    return createNoteServiceImpl();
  }

  static ConfigService createConfigService() {
    return createConfigServiceImpl();
  }
}
