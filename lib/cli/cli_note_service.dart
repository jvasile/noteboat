import 'dart:io';
import '../models/note.dart';
import '../services/file_service.dart';
import '../config/config_repository.dart';

/// Pure Dart note service for CLI commands (no Flutter dependencies)
class CliNoteService {
  final ConfigRepository _configRepository;
  final List<Note> _notes = [];
  bool _initialized = false;

  CliNoteService(this._configRepository);

  /// Initialize by loading all notes from configured directories
  Future<void> initialize() async {
    if (_initialized) return;

    final directories = await _configRepository.getAllDirectories();

    for (final directory in directories) {
      final dir = Directory(directory);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.md')) {
          try {
            final note = await FileService.readNoteFromFile(entity.path, autoFix: false);
            if (note != null) {
              _notes.add(note);
            }
          } catch (e) {
            // Skip files that can't be parsed
            continue;
          }
        }
      }
    }

    _initialized = true;
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    if (!_initialized) {
      await initialize();
    }
    return List.from(_notes);
  }

  /// Search notes by query string
  Future<List<Note>> searchNotes(String query) async {
    if (!_initialized) {
      await initialize();
    }

    if (query.isEmpty) {
      return getAllNotes();
    }

    final terms = query.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();

    return _notes.where((note) {
      final searchableText = '${note.title} ${note.text} ${note.tags.join(' ')}'.toLowerCase();
      return terms.every((term) => searchableText.contains(term));
    }).toList();
  }
}
