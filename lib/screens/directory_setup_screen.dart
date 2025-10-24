import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../services/config_service.dart';

/// Screen shown when no valid data directories exist
/// Forces user to configure at least one valid directory before continuing
class DirectorySetupScreen extends StatefulWidget {
  final ConfigService configService;
  final Map<String, String?> invalidDirectories;

  const DirectorySetupScreen({
    super.key,
    required this.configService,
    required this.invalidDirectories,
  });

  @override
  State<DirectorySetupScreen> createState() => _DirectorySetupScreenState();
}

class _DirectorySetupScreenState extends State<DirectorySetupScreen> {
  late List<DirectoryEntry> _directories;
  bool _isValidating = false;
  bool _isSaving = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _directories = widget.invalidDirectories.entries
        .map((e) => DirectoryEntry(path: e.key, error: e.value))
        .toList();

    // Add default directory if list is empty
    if (_directories.isEmpty) {
      _directories.add(DirectoryEntry(path: _getDefaultDirectory(), error: null));
    }
  }

  String _getDefaultDirectory() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) {
      return '';
    }

    if (Platform.isLinux || Platform.isMacOS) {
      return path.join(home, 'noteboat', 'notes');
    } else if (Platform.isWindows) {
      return path.join(home, 'Documents', 'noteboat', 'notes');
    } else {
      return path.join(home, 'noteboat', 'notes');
    }
  }

  Future<void> _validateDirectories() async {
    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    for (var dir in _directories) {
      if (dir.path.trim().isEmpty) {
        dir.error = 'Path cannot be empty';
        continue;
      }

      dir.error = await widget.configService.validateDirectory(dir.path);
    }

    setState(() {
      _isValidating = false;

      final validCount = _directories.where((d) => d.error == null).length;
      if (validCount == 0) {
        _validationMessage = 'At least one directory must be valid to continue';
      } else {
        _validationMessage = 'Found $validCount valid director${validCount == 1 ? 'y' : 'ies'}';
      }
    });
  }

  Future<void> _saveAndContinue() async {
    // Validate first
    await _validateDirectories();

    final validDirs = _directories
        .where((d) => d.error == null && d.path.trim().isNotEmpty)
        .map((d) => d.path)
        .toList();

    if (validDirs.isEmpty) {
      setState(() {
        _validationMessage = 'Cannot continue without at least one valid directory';
      });
      return;
    }

    setState(() => _isSaving = true);

    try {
      final config = await widget.configService.loadConfig();
      final updatedConfig = AppConfig(
        directories: validDirs,
        defaultEditor: config.defaultEditor,
        themeMode: config.themeMode,
        baseFontSize: config.baseFontSize,
        editorMode: config.editorMode,
        nvimFontSize: config.nvimFontSize,
        hotkeys: config.hotkeys,
      );

      await widget.configService.saveConfig(updatedConfig);

      if (mounted) {
        // Pop with success - main.dart will restart initialization
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationMessage = 'Error saving configuration: $e';
          _isSaving = false;
        });
      }
    }
  }

  void _addDirectory() {
    setState(() {
      _directories.add(DirectoryEntry(path: '', error: null));
    });
  }

  void _removeDirectory(int index) {
    setState(() {
      _directories.removeAt(index);
      _validationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory Setup Required'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        automaticallyImplyLeading: false, // Cannot go back
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Valid Data Directory',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Noteboat needs at least one valid directory to store your notes. Please configure a directory below.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Note Directories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addDirectory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Directory'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _directories.length,
                itemBuilder: (context, index) {
                  final dir = _directories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(text: dir.path)
                                    ..selection = TextSelection.collapsed(
                                      offset: dir.path.length,
                                    ),
                                  onChanged: (value) {
                                    dir.path = value;
                                    dir.error = null;
                                    setState(() {
                                      _validationMessage = null;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Directory Path',
                                    hintText: '/path/to/notes',
                                    border: const OutlineInputBorder(),
                                    errorText: dir.error,
                                    errorMaxLines: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Remove',
                                onPressed: _directories.length > 1
                                    ? () => _removeDirectory(index)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_validationMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  color: _validationMessage!.contains('valid director')
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _validationMessage!.contains('valid director')
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: _validationMessage!.contains('valid director')
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _validationMessage!,
                            style: TextStyle(
                              color: _validationMessage!.contains('valid director')
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: _isValidating ? null : _validateDirectories,
                  icon: _isValidating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Validate'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: (_isValidating || _isSaving) ? null : _saveAndContinue,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save & Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DirectoryEntry {
  String path;
  String? error;

  DirectoryEntry({required this.path, this.error});
}
