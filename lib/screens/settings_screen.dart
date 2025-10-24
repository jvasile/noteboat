import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/config_service.dart';

class SettingsScreen extends StatefulWidget {
  final ConfigService configService;
  final Function(ThemeMode)? onThemeChanged;
  final ThemeMode? currentThemeMode;

  const SettingsScreen({
    super.key,
    required this.configService,
    this.onThemeChanged,
    this.currentThemeMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _editorController;
  late TextEditingController _newNoteController;
  late TextEditingController _searchController;
  late TextEditingController _editNoteController;
  late TextEditingController _viewModeController;
  late TextEditingController _navigateBackController;
  late TextEditingController _moveUpController;
  late TextEditingController _moveDownController;
  late TextEditingController _closeDialogController;
  AppConfig? _config;
  bool _isLoading = true;
  bool _isSaving = false;
  late ThemeMode _selectedThemeMode;
  double _baseFontSize = 16.0;
  String _editorMode = 'basic';
  double _nvimFontSize = 16.0;
  List<String> _directories = [];
  Map<String, String?> _directoryValidation = {};

  @override
  void initState() {
    super.initState();
    _editorController = TextEditingController();
    _newNoteController = TextEditingController();
    _searchController = TextEditingController();
    _editNoteController = TextEditingController();
    _viewModeController = TextEditingController();
    _navigateBackController = TextEditingController();
    _moveUpController = TextEditingController();
    _moveDownController = TextEditingController();
    _closeDialogController = TextEditingController();
    _selectedThemeMode = widget.currentThemeMode ?? ThemeMode.system;
    _loadConfig();
  }

  @override
  void dispose() {
    _editorController.dispose();
    _newNoteController.dispose();
    _searchController.dispose();
    _editNoteController.dispose();
    _viewModeController.dispose();
    _navigateBackController.dispose();
    _moveUpController.dispose();
    _moveDownController.dispose();
    _closeDialogController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    final config = await widget.configService.loadConfig();

    setState(() {
      _config = config;
      _editorController.text = config.defaultEditor;
      _baseFontSize = config.baseFontSize;
      _editorMode = config.editorMode;
      _nvimFontSize = config.nvimFontSize;
      _directories = List.from(config.directories);
      _newNoteController.text = config.hotkeys.newNote;
      _searchController.text = config.hotkeys.search;
      _editNoteController.text = config.hotkeys.editNote;
      _viewModeController.text = config.hotkeys.viewMode;
      _navigateBackController.text = config.hotkeys.navigateBack;
      _moveUpController.text = config.hotkeys.moveUp;
      _moveDownController.text = config.hotkeys.moveDown;
      _closeDialogController.text = config.hotkeys.closeDialog;
      _isLoading = false;
    });

    // Validate directories
    _validateDirectories();
  }

  Future<void> _validateDirectories() async {
    final validation = await widget.configService.validateAllDirectories();
    setState(() {
      _directoryValidation = validation;
    });
  }

  bool _hasUnsavedChanges() {
    if (_config == null) return false;

    // Check if editor field changed
    final editorChanged = _editorController.text.trim() != _config!.defaultEditor;

    // Check if theme changed (compare with original from widget parameter)
    final originalTheme = widget.currentThemeMode ?? ThemeMode.system;
    final themeChanged = _selectedThemeMode != originalTheme;

    // Check if font size changed
    final fontSizeChanged = _baseFontSize != _config!.baseFontSize;

    // Check if editor mode changed
    final editorModeChanged = _editorMode != _config!.editorMode;

    // Check if nvim font size changed
    final nvimFontSizeChanged = _nvimFontSize != _config!.nvimFontSize;

    // Check if directories changed
    final directoriesChanged = _directories.length != _config!.directories.length ||
        !_directories.every((d) => _config!.directories.contains(d));

    // Check if hotkeys changed
    final hotkeysChanged =
      _newNoteController.text != _config!.hotkeys.newNote ||
      _searchController.text != _config!.hotkeys.search ||
      _editNoteController.text != _config!.hotkeys.editNote ||
      _viewModeController.text != _config!.hotkeys.viewMode ||
      _navigateBackController.text != _config!.hotkeys.navigateBack ||
      _moveUpController.text != _config!.hotkeys.moveUp ||
      _moveDownController.text != _config!.hotkeys.moveDown ||
      _closeDialogController.text != _config!.hotkeys.closeDialog;

    return editorChanged || themeChanged || fontSizeChanged || editorModeChanged || nvimFontSizeChanged || directoriesChanged || hotkeysChanged;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _DiscardChangesDialog(),
    );

    return result ?? false;
  }

  Future<void> _handleClose() async {
    if (await _confirmDiscard()) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    // Validate that at least one directory is valid
    final validDirs = _directories.where((dir) =>
      dir.trim().isNotEmpty &&
      (_directoryValidation[dir] == null || _directoryValidation[dir]!.isEmpty)
    ).toList();

    if (validDirs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot save: At least one valid directory is required'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedConfig = AppConfig(
        directories: _directories.where((d) => d.trim().isNotEmpty).toList(),
        defaultEditor: _editorController.text.trim(),
        themeMode: _config!.themeMode,
        baseFontSize: _baseFontSize,
        editorMode: _editorMode,
        nvimFontSize: _nvimFontSize,
        hotkeys: HotkeyConfig(
          newNote: _newNoteController.text,
          search: _searchController.text,
          editNote: _editNoteController.text,
          viewMode: _viewModeController.text,
          navigateBack: _navigateBackController.text,
          moveUp: _moveUpController.text,
          moveDown: _moveDownController.text,
          closeDialog: _closeDialogController.text,
        ),
      );

      await widget.configService.saveConfig(updatedConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isControlPressed = HardwareKeyboard.instance.isControlPressed;
          final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

          // Handle Ctrl-S to save
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              (isControlPressed || isMetaPressed)) {
            _saveConfig();
            return KeyEventResult.handled;
          }

          // Handle Escape to close
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _handleClose();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleClose,
          ),
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: _saveConfig,
              ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editor Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your default editor name for new notes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _editorController,
                    decoration: const InputDecoration(
                      labelText: 'Default Editor',
                      hintText: 'Your name',
                      border: OutlineInputBorder(),
                      helperText: 'This will be used for all new notes',
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Theme settings
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred theme',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (widget.onThemeChanged != null)
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto),
                        ),
                      ],
                      selected: {_selectedThemeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        setState(() {
                          _selectedThemeMode = newSelection.first;
                        });
                        widget.onThemeChanged!(newSelection.first);
                      },
                    ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Editor mode settings
                  Text(
                    'Editor Mode',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Platform.isLinux || Platform.isMacOS
                        ? 'Choose between basic editor or Neovim'
                        : 'Neovim is only available on Linux/macOS',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: [
                      const ButtonSegment<String>(
                        value: 'basic',
                        label: Text('Basic'),
                        icon: Icon(Icons.edit),
                      ),
                      ButtonSegment<String>(
                        value: 'nvim',
                        label: const Text('Neovim'),
                        icon: const Icon(Icons.terminal),
                        enabled: Platform.isLinux || Platform.isMacOS,
                      ),
                    ],
                    selected: {_editorMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _editorMode = newSelection.first;
                      });
                    },
                  ),
                  if (_editorMode == 'nvim' && (Platform.isLinux || Platform.isMacOS)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Neovim must be installed on your system. Your nvim config will be used. Save in nvim to save the note, :q to close editor.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Neovim Font Size:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _nvimFontSize,
                            min: 10.0,
                            max: 24.0,
                            divisions: 14,
                            label: _nvimFontSize.toStringAsFixed(0),
                            onChanged: (value) {
                              setState(() {
                                _nvimFontSize = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            _nvimFontSize.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Font size settings
                  Text(
                    'Display',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adjust the base font size for note content',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Font Size:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: _baseFontSize,
                          min: 12.0,
                          max: 24.0,
                          divisions: 12,
                          label: _baseFontSize.toStringAsFixed(0),
                          onChanged: (value) {
                            setState(() {
                              _baseFontSize = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          _baseFontSize.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Sample text at current size',
                        style: TextStyle(
                          fontSize: _baseFontSize,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Hotkey settings
                  Text(
                    'Keyboard Shortcuts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize keyboard shortcuts. Use comma-separated values for multiple keys (e.g., "Escape,Alt+ArrowLeft")',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newNoteController,
                    decoration: const InputDecoration(
                      labelText: 'New Note',
                      border: OutlineInputBorder(),
                      helperText: 'Create a new note',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                      helperText: 'Focus search field',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _editNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Edit Note',
                      border: OutlineInputBorder(),
                      helperText: 'Edit selected note',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _viewModeController,
                    decoration: const InputDecoration(
                      labelText: 'View Mode',
                      border: OutlineInputBorder(),
                      helperText: 'Switch to view mode',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _navigateBackController,
                    decoration: const InputDecoration(
                      labelText: 'Navigate Back',
                      border: OutlineInputBorder(),
                      helperText: 'Go back to previous screen',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _moveUpController,
                    decoration: const InputDecoration(
                      labelText: 'Move Up',
                      border: OutlineInputBorder(),
                      helperText: 'Move selection up in lists',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _moveDownController,
                    decoration: const InputDecoration(
                      labelText: 'Move Down',
                      border: OutlineInputBorder(),
                      helperText: 'Move selection down in lists',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _closeDialogController,
                    decoration: const InputDecoration(
                      labelText: 'Close Dialog',
                      border: OutlineInputBorder(),
                      helperText: 'Close dialogs and popups',
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Storage',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _validateDirectories,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Validate'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _directories.add('');
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Directory'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure where notes are stored. At least one valid directory is required.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._directories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dir = entry.value;
                    final error = _directoryValidation[dir];
                    final isValid = error == null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isValid
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isValid ? Icons.check_circle : Icons.error_outline,
                                  color: isValid
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(text: dir)
                                      ..selection = TextSelection.collapsed(
                                        offset: dir.length,
                                      ),
                                    onChanged: (value) {
                                      setState(() {
                                        _directories[index] = value;
                                        _directoryValidation.remove(dir);
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      hintText: '/path/to/notes',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Remove',
                                  onPressed: _directories.length > 1
                                      ? () {
                                          setState(() {
                                            _directories.removeAt(index);
                                            _directoryValidation.remove(dir);
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                            if (!isValid) ...[
                              const SizedBox(height: 8),
                              Text(
                                error ?? 'Unknown error',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About Noteboat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Version: 1.0.0',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text(
                            'Notes are stored as markdown files with YAML frontmatter',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text(
                            'You can edit them directly or sync with git',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

/// Keyboard-navigable discard changes confirmation dialog
class _DiscardChangesDialog extends StatefulWidget {
  const _DiscardChangesDialog();

  @override
  State<_DiscardChangesDialog> createState() => _DiscardChangesDialogState();
}

class _DiscardChangesDialogState extends State<_DiscardChangesDialog> {
  int _selectedIndex = 0; // 0 = Cancel, 1 = Discard

  void _selectOption() {
    Navigator.pop(context, _selectedIndex == 1);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              _selectedIndex = (_selectedIndex + 1) % 2;
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _selectOption();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context, false);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            style: FilledButton.styleFrom(
              backgroundColor: _selectedIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: _selectedIndex == 0
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _selectedIndex == 1
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: _selectedIndex == 1
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
