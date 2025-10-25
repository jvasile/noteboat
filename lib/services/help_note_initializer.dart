import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'note_service.dart';

/// Helper to initialize the Help note for the GUI
/// Separated from NoteService to avoid Flutter dependencies in pure Dart code
class HelpNoteInitializer {
  /// Ensure "Help" note exists by copying from bundled asset
  /// This should only be called when no notes exist at all (i.e., user is starting fresh)
  static Future<void> ensureHelpNote(NoteService noteService) async {
    // Only create Help note if no notes exist at all
    final allNotes = await noteService.getAllNotes();
    if (allNotes.isNotEmpty) {
      // User has notes, don't create Help.md even if they deleted it
      return;
    }

    // Load bundled Help.md file
    final helpContent = await rootBundle.loadString('assets/Help.md');

    // Write directly to notes directory
    final writeDir = await noteService.configService.getWriteDirectory();

    // Ensure the directory exists before writing
    final dir = Directory(writeDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final helpPath = path.join(writeDir, 'Help.md');
    await File(helpPath).writeAsString(helpContent);

    // Reload notes to include the new Help.md
    await noteService.reload();
  }
}
