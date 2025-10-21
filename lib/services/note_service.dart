import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../utils/link_extractor.dart';
import '../utils/tag_extractor.dart';
import 'config_service.dart';
import 'file_service.dart';

class NoteService {
  final ConfigService configService;
  final Map<String, Note> _noteCache = {}; // Cache notes by title (lowercase)
  final Map<String, String> _noteFilePaths = {}; // Map title -> file path
  bool _initialized = false;

  NoteService(this.configService);

  // Initialize and load all notes
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadAllNotes();
    _initialized = true;
  }

  // Load all notes from all configured directories
  Future<void> _loadAllNotes() async {
    _noteCache.clear();
    _noteFilePaths.clear();

    final directories = await configService.getAllDirectories();

    for (final dir in directories) {
      final noteFiles = await FileService.getAllNoteFiles(dir);

      for (final filePath in noteFiles) {
        final note = await FileService.readNoteFromFile(filePath);
        if (note != null) {
          final key = note.title.toLowerCase();

          // Handle duplicate titles - keep the one with matching @id or the first one
          if (!_noteCache.containsKey(key)) {
            _noteCache[key] = note;
            _noteFilePaths[key] = filePath;
          }
        }
      }
    }
  }

  // Get all notes
  Future<List<Note>> getAllNotes() async {
    if (!_initialized) await initialize();
    return _noteCache.values.toList()..sort((a, b) => b.mtime.compareTo(a.mtime));
  }

  // Get note by title (case-insensitive)
  Future<Note?> getNoteByTitle(String title) async {
    if (!_initialized) await initialize();
    return _noteCache[title.toLowerCase()];
  }

  // Search notes (case-insensitive, searches all fields)
  Future<List<Note>> searchNotes(String query) async {
    if (!_initialized) await initialize();

    if (query.isEmpty) {
      return getAllNotes();
    }

    final lowerQuery = query.toLowerCase();
    final results = <Note>[];

    for (final note in _noteCache.values) {
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

    for (final note in _noteCache.values) {
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
    final links = LinkExtractor.extractAllLinks(note.text, note.extraFields);
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
    final key = updatedNote.title.toLowerCase();

    if (existingTitle != null && existingTitle.toLowerCase() != key) {
      // Title changed - delete old file and create new one
      final oldKey = existingTitle.toLowerCase();
      final oldPath = _noteFilePaths[oldKey];
      if (oldPath != null) {
        await FileService.deleteNoteFile(oldPath);
        _noteCache.remove(oldKey);
        _noteFilePaths.remove(oldKey);
      }

      // Create new file path
      final writeDir = await configService.getWriteDirectory();
      filePath = path.join(writeDir, '${updatedNote.title}.md');
    } else if (_noteFilePaths.containsKey(key)) {
      // Update existing note
      filePath = _noteFilePaths[key]!;
    } else {
      // New note
      final writeDir = await configService.getWriteDirectory();
      filePath = path.join(writeDir, '${updatedNote.title}.md');
    }

    // Write to file
    await FileService.writeNoteToFile(updatedNote, filePath);

    // Update cache
    _noteCache[key] = updatedNote;
    _noteFilePaths[key] = filePath;
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

  // Delete a note
  Future<void> deleteNote(String title) async {
    if (!_initialized) await initialize();

    final key = title.toLowerCase();
    final filePath = _noteFilePaths[key];

    if (filePath != null) {
      await FileService.deleteNoteFile(filePath);
      _noteCache.remove(key);
      _noteFilePaths.remove(key);
    }
  }

  // Check if a note exists
  Future<bool> noteExists(String title) async {
    if (!_initialized) await initialize();
    return _noteCache.containsKey(title.toLowerCase());
  }

  // Ensure "Main" note exists
  Future<void> ensureMainNote() async {
    if (!await noteExists('Main')) {
      await createNote(
        title: 'Main',
        text: '''# Welcome to Noteboat!

This is your main note. You can edit it by clicking the Edit button.

## Features

- Create linked notes using CamelCase words like ThisIsALink
- Add tags using #hashtags
- Browse and search all your notes
- Notes are stored as markdown files with YAML frontmatter

## Getting Started

Click the Edit button to modify this note, or use the List button to see all notes.
''',
      );
    }
  }

  // Reload all notes from disk
  Future<void> reload() async {
    await _loadAllNotes();
  }
}
