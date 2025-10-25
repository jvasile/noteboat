import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import '../server/api_handlers.dart';
import '../server/auth_middleware.dart';
import '../services/config_service.dart';
import '../services/note_service.dart';
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
  print('  serve [options]         Start HTTP server for web client');
  print('  --version, -v           Show version information');
  print('  help, --help, -h        Show this help message');
  print('  (no arguments)          Launch GUI');
  print('');
  print('Serve options:');
  print('  --port <port>           Port to listen on (default: 8080)');
  print('  --password <password>   Password for basic auth (optional)');
  print('  --web-dir <path>        Path to web build directory (default: build/web)');
  print('');
  print('Examples:');
  print('  noteboat list');
  print('  noteboat search foo bar baz');
  print('  noteboat serve --port 8080 --password mypass');
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

/// Handle 'serve' command
Future<void> handleServeCommand(List<String> args) async {
  // Parse arguments
  int port = 8080;
  String? password;
  String webDir = 'build/web';

  for (int i = 1; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? 8080;
      i++;
    } else if (args[i] == '--password' && i + 1 < args.length) {
      password = args[i + 1];
      i++;
    } else if (args[i] == '--web-dir' && i + 1 < args.length) {
      webDir = args[i + 1];
      i++;
    }
  }

  // Initialize NoteService
  final configService = ConfigService();
  final noteService = NoteService(configService);
  await noteService.initialize();

  // Create API handlers
  final apiHandlers = ApiHandlers(noteService);

  // Create auth middleware
  final authMiddleware = AuthMiddleware(password: password);

  // Mount API router at /api path
  final apiRouter = Router()
    ..mount('/api/', apiHandlers.router);

  // Create cascade handler: try API routes first, then static files
  final handler = Cascade()
      .add(apiRouter)
      .add(createStaticHandler(
        webDir,
        defaultDocument: 'index.html',
      ))
      .handler;

  // Wrap with middleware
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(authMiddleware.handler)
      .addHandler(handler);

  // Start server
  final server = await io.serve(pipeline, InternetAddress.anyIPv4, port);
  print('Noteboat server running on http://localhost:$port');
  if (password != null) {
    print('Authentication enabled (password protected)');
  } else {
    print('WARNING: No password set - server is publicly accessible!');
  }
  print('Press Ctrl+C to stop');
}
