/// Barrel file for all note type handlers
/// Importing this file ensures all types are registered with the registry

export 'note_type_handler.dart';
export 'linked_list_note_handler.dart';

// Import to trigger static registration
import 'linked_list_note_handler.dart';

// Force static initialization by accessing the static field
void ensureTypesRegistered() {
  // This forces the LinkedListNoteHandler class to load and run its static initializer
  LinkedListNoteHandler.registered;
}
