import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/config_service.dart';
import 'services/note_service.dart';
import 'services/note_service_interface.dart';
import 'services/help_note_initializer.dart';
import 'screens/list_view_screen.dart';
import 'screens/directory_setup_screen.dart';
import 'providers.dart';
import 'types/types.dart'; // Import early to ensure type registration
import 'version.dart'; // Generated at build time

export 'services/config_service.dart' show AppConfig;

void main() async {
  // Ensure all note types are registered before starting the app
  ensureTypesRegistered();

  // Run the GUI wrapped in ProviderScope
  runApp(
    const ProviderScope(
      child: NoteboatApp(),
    ),
  );
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

class NoteboatHome extends ConsumerStatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const NoteboatHome({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  ConsumerState<NoteboatHome> createState() => _NoteboatHomeState();
}

class _NoteboatHomeState extends ConsumerState<NoteboatHome> {
  bool _isInitializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      // Get services from providers
      final configService = ref.read(configServiceProvider);
      final noteService = ref.read(noteServiceProvider);

      // On web, skip directory validation (uses HTTP repository)
      if (!kIsWeb) {
        // Check if we have at least one valid directory (desktop only)
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
      }

      // We have valid directories (or we're on web), continue with normal initialization
      // Load all notes
      await noteService.initialize();

      // Ensure Help note exists if no notes exist at all (desktop only)
      if (!kIsWeb) {
        final allNotes = await noteService.getAllNotes();
        if (allNotes.isEmpty && noteService is NoteService) {
          await HelpNoteInitializer.ensureHelpNote(noteService as NoteService);
        }
      }

      setState(() => _isInitializing = false);

      // Navigate to list view (search screen)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ListViewScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
      });

      if (mounted) {
        // Show error dialog instead of snackbar for better visibility
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                const Text('Initialization Error'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The application failed to initialize:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    e.toString(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final configService = ref.read(configServiceProvider);
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
                child: const Text('Configure Directories'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _initializeApp(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
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
            const SizedBox(height: 16),
            Text(
              'v$appVersion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            Text(
              'Built: $buildTimestamp',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 32),
            if (_isInitializing && !_hasError)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
            if (_hasError && !_isInitializing)
              Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initialization failed',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check the error dialog for details',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
