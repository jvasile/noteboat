import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../utils/link_extractor.dart';
import '../utils/tag_extractor.dart';
import 'config_service.dart';
import 'file_service.dart';

class NoteService {
  final ConfigService configService;
  final Map<String, List<Note>> _noteCache = {}; // Cache notes by title (lowercase) - can have duplicates
  final Map<String, Note> _noteCacheById = {}; // Cache notes by ID
  final Map<String, String> _noteFilePaths = {}; // Map ID -> file path
  bool _initialized = false;

  NoteService(this.configService);

  /// Sanitize a note title for use as a filename
  /// Replaces forward slashes with dashes to prevent directory creation
  /// The title in the note's frontmatter remains unchanged
  String _sanitizeFilename(String title) {
    return title.replaceAll('/', '-');
  }

  // Initialize and load all notes
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadAllNotes();
    _initialized = true;
  }

  // Load all notes from all configured directories
  Future<void> _loadAllNotes() async {
    _noteCache.clear();
    _noteCacheById.clear();
    _noteFilePaths.clear();

    final directories = await configService.getAllDirectories();

    for (final dir in directories) {
      final noteFiles = await FileService.getAllNoteFiles(dir);

      for (final filePath in noteFiles) {
        final note = await FileService.readNoteFromFile(filePath);
        if (note != null) {
          final titleKey = note.title.toLowerCase();

          // Add to title cache (supporting multiple notes with same title)
          if (!_noteCache.containsKey(titleKey)) {
            _noteCache[titleKey] = [];
          }
          _noteCache[titleKey]!.add(note);

          // Add to ID cache
          _noteCacheById[note.id] = note;
          _noteFilePaths[note.id] = filePath;
        }
      }
    }
  }

  // Get all notes
  Future<List<Note>> getAllNotes() async {
    if (!_initialized) await initialize();
    return _noteCacheById.values.toList()..sort((a, b) => b.mtime.compareTo(a.mtime));
  }

  // Get note by title (case-insensitive)
  // Returns first note if multiple exist, or null if none exist
  Future<Note?> getNoteByTitle(String title) async {
    if (!_initialized) await initialize();
    final notes = _noteCache[title.toLowerCase()];
    return (notes != null && notes.isNotEmpty) ? notes.first : null;
  }

  // Get all notes by title (case-insensitive)
  // Returns empty list if no notes found
  Future<List<Note>> getNotesByTitle(String title) async {
    if (!_initialized) await initialize();
    return _noteCache[title.toLowerCase()] ?? [];
  }

  // Get note by ID
  Future<Note?> getNoteById(String id) async {
    if (!_initialized) await initialize();
    return _noteCacheById[id];
  }

  // Search notes (case-insensitive, searches all fields)
  Future<List<Note>> searchNotes(String query) async {
    if (!_initialized) await initialize();

    if (query.isEmpty) {
      return getAllNotes();
    }

    final lowerQuery = query.toLowerCase();
    final results = <Note>[];

    for (final note in _noteCacheById.values) {
      // Search in title, text, tags, links, and extra fields
      if (note.title.toLowerCase().contains(lowerQuery) ||
          note.text.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          note.links.any((link) => link.toLowerCase().contains(lowerQuery)) ||
          note.extraFields.values.any((value) =>
              value.toString().toLowerCase().contains(lowerQuery))) {
        results.add(note);
      }
    }

    return results..sort((a, b) => b.mtime.compareTo(a.mtime));
  }

  // Get notes by tag
  Future<List<Note>> getNotesByTag(String tag) async {
    if (!_initialized) await initialize();

    final lowerTag = tag.toLowerCase();
    final results = <Note>[];

    for (final note in _noteCacheById.values) {
      if (note.tags.any((t) => t.toLowerCase() == lowerTag)) {
        results.add(note);
      }
    }

    return results..sort((a, b) => b.mtime.compareTo(a.mtime));
  }

  // Save or update a note
  Future<void> saveNote(Note note, {String? existingTitle}) async {
    if (!_initialized) await initialize();

    // Update derived fields (links and tags)
    // Exclude self-references from links
    final links = LinkExtractor.extractAllLinks(note.text, note.extraFields, excludeTitle: note.title);
    final tags = TagExtractor.extractAllTags(note.text, note.extraFields);

    // Add current user to editors list if not already present
    final config = await configService.loadConfig();
    final currentEditor = config.defaultEditor;
    final updatedEditors = List<String>.from(note.editors);
    if (currentEditor.isNotEmpty && !updatedEditors.contains(currentEditor)) {
      updatedEditors.add(currentEditor);
    }

    final updatedNote = note.copyWith(
      links: links,
      tags: tags,
      editors: updatedEditors,
      mtime: DateTime.now(),
    );

    // Get file path
    String filePath;
    final titleKey = updatedNote.title.toLowerCase();
    final id = updatedNote.id;

    if (existingTitle != null && existingTitle.toLowerCase() != titleKey) {
      // Title changed - need to update title cache and possibly delete old file
      final oldTitleKey = existingTitle.toLowerCase();

      // Remove from old title list
      if (_noteCache.containsKey(oldTitleKey)) {
        _noteCache[oldTitleKey]!.removeWhere((n) => n.id == id);
        if (_noteCache[oldTitleKey]!.isEmpty) {
          _noteCache.remove(oldTitleKey);
        }
      }

      // Delete old file if exists
      final oldPath = _noteFilePaths[id];
      if (oldPath != null) {
        await FileService.deleteNoteFile(oldPath);
      }

      // Create new file path with sanitized filename
      final writeDir = await configService.getWriteDirectory();
      final safeFilename = _sanitizeFilename(updatedNote.title);
      filePath = path.join(writeDir, '$safeFilename.md');
    } else if (_noteFilePaths.containsKey(id)) {
      // Update existing note
      filePath = _noteFilePaths[id]!;
    } else {
      // New note with sanitized filename
      final writeDir = await configService.getWriteDirectory();
      final safeFilename = _sanitizeFilename(updatedNote.title);
      filePath = path.join(writeDir, '$safeFilename.md');
    }

    // Write to file
    await FileService.writeNoteToFile(updatedNote, filePath);

    // Update caches
    // Update title cache
    if (!_noteCache.containsKey(titleKey)) {
      _noteCache[titleKey] = [];
    }
    // Remove old entry from title cache (in case it exists)
    _noteCache[titleKey]!.removeWhere((n) => n.id == id);
    // Add updated note
    _noteCache[titleKey]!.add(updatedNote);

    // Update ID cache
    _noteCacheById[id] = updatedNote;
    _noteFilePaths[id] = filePath;
  }

  // Create a new note
  Future<Note> createNote({
    required String title,
    String text = '',
    List<String>? types,
    Map<String, dynamic>? extraFields,
  }) async {
    final config = await configService.loadConfig();
    final defaultEditor = config.defaultEditor;

    // Start with default editor in the list if provided
    final editors = defaultEditor.isNotEmpty ? [defaultEditor] : <String>[];

    final note = Note(
      id: const Uuid().v4(),
      title: title,
      text: text,
      mtime: DateTime.now(),
      editors: editors,
      types: types,
      extraFields: extraFields,
    );

    await saveNote(note);
    return note;
  }

  // Delete a note by ID
  Future<void> deleteNoteById(String id) async {
    if (!_initialized) await initialize();

    final note = _noteCacheById[id];
    if (note == null) return;

    final filePath = _noteFilePaths[id];
    if (filePath != null) {
      await FileService.deleteNoteFile(filePath);
    }

    // Remove from title cache
    final titleKey = note.title.toLowerCase();
    if (_noteCache.containsKey(titleKey)) {
      _noteCache[titleKey]!.removeWhere((n) => n.id == id);
      if (_noteCache[titleKey]!.isEmpty) {
        _noteCache.remove(titleKey);
      }
    }

    // Remove from ID cache
    _noteCacheById.remove(id);
    _noteFilePaths.remove(id);
  }

  // Delete a note by title (deletes first note with that title if multiple exist)
  Future<void> deleteNote(String title) async {
    final note = await getNoteByTitle(title);
    if (note != null) {
      await deleteNoteById(note.id);
    }
  }

  // Check if a note exists
  Future<bool> noteExists(String title) async {
    if (!_initialized) await initialize();
    final notes = _noteCache[title.toLowerCase()];
    return notes != null && notes.isNotEmpty;
  }

  // Ensure "Help" note exists by copying from bundled asset
  Future<void> ensureHelpNote() async {
    if (!await noteExists('Help')) {
      // Load bundled Help.md file
      final helpContent = await rootBundle.loadString('assets/Help.md');

      // Write directly to notes directory
      final writeDir = await configService.getWriteDirectory();
      final helpPath = path.join(writeDir, 'Help.md');
      await File(helpPath).writeAsString(helpContent);

      // Reload notes to include the new Help.md
      await reload();
    }
  }

  // Reload all notes from disk
  Future<void> reload() async {
    await _loadAllNotes();
  }
}
