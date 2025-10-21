import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_markdown_viewer.dart';
import '../screens/edit_screen.dart';

/// Abstract base class for note type handlers
/// Each note type implements this to provide custom viewer and editor widgets
abstract class NoteTypeHandler {
  /// Build the viewer widget for this note type
  Widget buildViewer({
    required BuildContext context,
    required Note note,
    required NoteService noteService,
    required Function(String) onNoteLinkTap,
    required Function(String) onTagTap,
    required VoidCallback onRefresh,
    double baseFontSize = 16.0,
    Set<String> existingNoteTitles = const {},
  });

  /// Build the editor widget for this note type
  Widget buildEditor({
    required BuildContext context,
    required Note note,
    required NoteService noteService,
    required Function(bool) onComplete,
  });

  /// Handle custom keyboard events for this note type
  /// Returns KeyEventResult.handled if the event was handled, KeyEventResult.ignored otherwise
  /// Default implementation ignores all events
  KeyEventResult handleKeyEvent({
    required Note note,
    required KeyEvent event,
    required Function(String) onNoteLinkTap,
  }) {
    return KeyEventResult.ignored;
  }
}

/// Registry singleton for note type handlers
class NoteTypeRegistry {
  static final NoteTypeRegistry _instance = NoteTypeRegistry._internal();
  static NoteTypeRegistry get instance => _instance;

  final Map<String, NoteTypeHandler> _handlers = {};

  NoteTypeRegistry._internal() {
    // Register base note type handler
    register('note', BaseNoteHandler());
  }

  /// Register a handler for a note type
  void register(String typeName, NoteTypeHandler handler) {
    _handlers[typeName] = handler;
  }

  /// Get handler for a note based on its types list
  /// Returns handler for first type in list, or base 'note' handler if not found
  NoteTypeHandler getHandler(List<String> types) {
    // Check types in order (most specific first)
    for (final type in types) {
      if (_handlers.containsKey(type)) {
        return _handlers[type]!;
      }
    }

    // Fallback to base note handler
    return _handlers['note']!;
  }

  /// Get all registered note type names
  /// Returns with 'note' (plain note) first, then others alphabetically
  List<String> getRegisteredTypes() {
    final types = _handlers.keys.toList();
    types.sort((a, b) {
      if (a == 'note') return -1;
      if (b == 'note') return 1;
      return a.compareTo(b);
    });
    return types;
  }

  /// Get a human-readable name for a note type
  String getTypeName(String type) {
    switch (type) {
      case 'note':
        return 'Plain Note';
      case 'linked_list_note':
        return 'Linked List Note';
      default:
        return type;
    }
  }
}

/// Base note type handler - wraps existing note viewer and editor
class BaseNoteHandler extends NoteTypeHandler {
  @override
  Widget buildViewer({
    required BuildContext context,
    required Note note,
    required NoteService noteService,
    required Function(String) onNoteLinkTap,
    required Function(String) onTagTap,
    required VoidCallback onRefresh,
    double baseFontSize = 16.0,
    Set<String> existingNoteTitles = const {},
  }) {
    return NoteMarkdownViewer(
      text: note.text,
      noteTitle: note.title,
      onNoteLinkTap: onNoteLinkTap,
      onTagTap: onTagTap,
      baseFontSize: baseFontSize,
      existingNoteTitles: existingNoteTitles,
    );
  }

  @override
  Widget buildEditor({
    required BuildContext context,
    required Note note,
    required NoteService noteService,
    required Function(bool) onComplete,
  }) {
    // Return the existing EditScreen
    // We'll navigate to it rather than embedding it
    return EditScreen(
      noteService: noteService,
      note: note,
    );
  }
}
