import 'dart:io';
import 'package:flutter/material.dart';
import 'services/config_service.dart';
import 'services/note_service.dart';
import 'screens/view_screen.dart';
import 'screens/edit_screen.dart';
import 'types/types.dart'; // Import early to ensure type registration

export 'services/config_service.dart' show AppConfig;

void main(List<String> args) async {
  // Ensure all note types are registered before starting the app
  ensureTypesRegistered();

  // If CLI arguments are provided, run in CLI mode
  if (args.isNotEmpty) {
    await runCLI(args);
    exit(0);
  }

  // Otherwise, run the GUI
  runApp(const NoteboatApp());
}

// CLI mode handler
Future<void> runCLI(List<String> args) async {
  if (args.isEmpty) {
    printHelp();
    return;
  }

  // Initialize services
  final configService = ConfigService();
  final noteService = NoteService(configService);
  await noteService.initialize();

  final command = args[0];

  switch (command) {
    case 'list':
      await handleListCommand(noteService);
      break;
    case 'search':
      await handleSearchCommand(noteService, args);
      break;
    case 'help':
      printHelp();
      break;
    default:
      print('Unknown command: $command');
      printHelp();
  }
}

// Handle 'list' command
Future<void> handleListCommand(NoteService noteService) async {
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

// Handle 'search' command
Future<void> handleSearchCommand(NoteService noteService, List<String> args) async {
  if (args.length < 2) {
    print('Usage: noteboat search <query terms...>');
    return;
  }

  // Join all search terms after 'search' into a single query
  final query = args.sublist(1).join(' ');
  final results = await noteService.searchNotes(query);

  if (results.isEmpty) {
    print('No notes found matching "$query"');
    return;
  }

  print('Notes matching "$query":');
  for (final note in results) {
    final preview = note.text.length > 50
        ? '${note.text.substring(0, 50)}...'
        : note.text;
    final cleanPreview = preview.replaceAll('\n', ' ');
    print('  ${note.title}: $cleanPreview');
  }
}

// Print help message
void printHelp() {
  print('Noteboat - Linked note-taking application');
  print('');
  print('Usage: noteboat [command] [arguments]');
  print('');
  print('Commands:');
  print('  list                    List all notes');
  print('  search <query>...       Search notes (multiple terms supported)');
  print('  help                    Show this help message');
  print('  (no arguments)          Launch GUI');
  print('');
  print('Examples:');
  print('  noteboat list');
  print('  noteboat search foo bar baz');
}

class NoteboatApp extends StatefulWidget {
  const NoteboatApp({super.key});

  @override
  State<NoteboatApp> createState() => _NoteboatAppState();
}

class _NoteboatAppState extends State<NoteboatApp> {
  ThemeMode _themeMode = ThemeMode.system;
  ConfigService? _configService;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    _configService = ConfigService();
    final config = await _configService!.loadConfig();
    setState(() {
      _themeMode = _themeModeFromString(config.themeMode);
    });
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> _toggleTheme(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    // Persist theme preference
    if (_configService != null) {
      final config = await _configService!.loadConfig();
      final updatedConfig = AppConfig(
        directories: config.directories,
        defaultEditor: config.defaultEditor,
        themeMode: _themeModeToString(mode),
      );
      await _configService!.saveConfig(updatedConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noteboat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: NoteboatHome(
        onThemeChanged: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class NoteboatHome extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const NoteboatHome({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<NoteboatHome> createState() => _NoteboatHomeState();
}

class _NoteboatHomeState extends State<NoteboatHome> {
  late NoteService _noteService;
  bool _isInitializing = true;
  bool _mainNoteExists = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isInitializing = true);

    try {
      // Initialize services
      final configService = ConfigService();
      _noteService = NoteService(configService);

      // Load all notes
      await _noteService.initialize();

      // Ensure Main note exists
      await _noteService.ensureMainNote();

      // Check if Main note exists
      final mainNote = await _noteService.getNoteByTitle('Main');
      _mainNoteExists = mainNote != null;

      setState(() => _isInitializing = false);

      // Navigate to appropriate screen
      if (mounted) {
        if (mainNote != null) {
          // Show Main note
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ViewScreen(
                noteService: _noteService,
                noteId: mainNote.id,
                onThemeChanged: widget.onThemeChanged,
                currentThemeMode: widget.currentThemeMode,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isInitializing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sailing,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Noteboat',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Linked Notes'),
            const SizedBox(height: 32),
            if (_isInitializing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
