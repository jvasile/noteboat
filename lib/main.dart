import 'package:flutter/material.dart';
import 'services/config_service.dart';
import 'services/note_service.dart';
import 'screens/list_view_screen.dart';
import 'screens/directory_setup_screen.dart';
import 'types/types.dart'; // Import early to ensure type registration

export 'services/config_service.dart' show AppConfig;

void main() async {
  // Ensure all note types are registered before starting the app
  ensureTypesRegistered();

  // Run the GUI
  runApp(const NoteboatApp());
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

      // Check if we have at least one valid directory
      final hasValidDir = await configService.hasValidDirectory();

      if (!hasValidDir) {
        // No valid directories - show directory setup screen
        setState(() => _isInitializing = false);

        if (!mounted) return;

        final invalidDirs = await configService.validateAllDirectories();
        if (!mounted) return;

        final result = await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DirectorySetupScreen(
              configService: configService,
              invalidDirectories: invalidDirs,
            ),
          ),
        );

        // If user successfully configured directories, restart initialization
        if (result == true && mounted) {
          _initializeApp();
        }
        return;
      }

      // We have valid directories, continue with normal initialization
      _noteService = NoteService(configService);

      // Load all notes
      await _noteService.initialize();

      // Ensure Help note exists if no notes exist at all
      final allNotes = await _noteService.getAllNotes();
      if (allNotes.isEmpty) {
        await _noteService.ensureHelpNote();
      }

      setState(() => _isInitializing = false);

      // Navigate to list view (search screen)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ListViewScreen(
              noteService: _noteService,
              onThemeChanged: widget.onThemeChanged,
              currentThemeMode: widget.currentThemeMode,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isInitializing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing app: $e'),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Configure',
              onPressed: () async {
                final configService = ConfigService();
                final invalidDirs = await configService.validateAllDirectories();
                if (mounted) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DirectorySetupScreen(
                        configService: configService,
                        invalidDirectories: invalidDirs,
                      ),
                    ),
                  );

                  if (result == true && mounted) {
                    _initializeApp();
                  }
                }
              },
            ),
          ),
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
