import 'package:flutter/material.dart';
import 'services/config_service.dart';
import 'services/note_service.dart';
import 'screens/view_screen.dart';
import 'screens/edit_screen.dart';

void main() {
  runApp(const NoteboatApp());
}

class NoteboatApp extends StatelessWidget {
  const NoteboatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noteboat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NoteboatHome(),
    );
  }
}

class NoteboatHome extends StatefulWidget {
  const NoteboatHome({super.key});

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
        if (_mainNoteExists) {
          // Show Main note
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ViewScreen(
                noteService: _noteService,
                noteTitle: 'Main',
              ),
            ),
          );
        } else {
          // Show edit screen for Main note (shouldn't happen, but just in case)
          final mainNote = await _noteService.getNoteByTitle('Main');
          if (mainNote != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EditScreen(
                  noteService: _noteService,
                  note: mainNote,
                ),
              ),
            );
          }
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
