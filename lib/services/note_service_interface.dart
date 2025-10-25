import '../models/note.dart';

/// Interface for note operations
/// Implemented by NoteService (desktop) and NoteServiceHttp (web)
abstract class INoteService {
  Future<void> initialize();
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteByTitle(String title);
  Future<List<Note>> getNotesByTitle(String title);
  Future<Note?> getNoteById(String id);
  Future<List<Note>> searchNotes(String query);
  Future<List<Note>> getNotesByTag(String tag);
  Future<void> saveNote(Note note, {String? existingTitle});
  Future<Note> createNote({
    required String title,
    String text = '',
    List<String>? types,
    Map<String, dynamic>? extraFields,
  });
  Future<void> deleteNoteById(String id);
  Future<void> deleteNote(String title);
  Future<bool> noteExists(String title);
  Future<void> reload();
}
