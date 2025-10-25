import 'dart:io';
import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import '../providers.dart';
import '../server/api_handlers.dart';
import '../server/auth_middleware.dart';
import '../services/note_service.dart';

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

  // Initialize services using Riverpod
  final container = ProviderContainer();
  final noteService = container.read(noteServiceProvider);
  await noteService.initialize();

  // Create API handlers
  final apiHandlers = ApiHandlers(noteService as NoteService);

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
