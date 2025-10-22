import 'cli_note_service.dart';

const String version = '1.0.0';

/// Print version information
void printVersion() {
  print(version);
}

/// Print help message
void printHelp() {
  print('Noteboat - Linked note-taking application');
  print('');
  print('Usage: noteboat [command] [arguments]');
  print('');
  print('Commands:');
  print('  list                    List all notes');
  print('  search <query>...       Search notes (multiple terms supported)');
  print('  --version, -v           Show version information');
  print('  help, --help, -h        Show this help message');
  print('  (no arguments)          Launch GUI');
  print('');
  print('Examples:');
  print('  noteboat list');
  print('  noteboat search foo bar baz');
  print('  noteboat --version');
}

/// Handle 'list' command
Future<void> handleListCommand(CliNoteService noteService) async {
  final notes = await noteService.getAllNotes();

  if (notes.isEmpty) {
    print('No notes found.');
    return;
  }

  print('All notes:');
  for (final note in notes) {
    final tagCount = note.tags.length;
    final linkCount = note.links.length;
    print('  ${note.title}: $tagCount tags, $linkCount links');
  }
}

/// Handle 'search' command
Future<void> handleSearchCommand(CliNoteService noteService, List<String> args) async {
  if (args.length < 2) {
    print('Usage: noteboat search <query terms...>');
    return;
  }

  final query = args.sublist(1).join(' ');
  final results = await noteService.searchNotes(query);

  if (results.isEmpty) {
    print('No notes found matching: $query');
    return;
  }

  print('Found ${results.length} note(s):');
  for (final note in results) {
    final preview = note.text.length > 50
        ? '${note.text.substring(0, 50)}...'
        : note.text;
    final cleanPreview = preview.replaceAll('\n', ' ');
    print('  ${note.title}: $cleanPreview');
  }
}
