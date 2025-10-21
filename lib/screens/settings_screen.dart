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
  AppConfig? _config;
  bool _isLoading = true;
  bool _isSaving = false;
  late ThemeMode _selectedThemeMode;
  double _baseFontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _editorController = TextEditingController();
    _selectedThemeMode = widget.currentThemeMode ?? ThemeMode.system;
    _loadConfig();
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    final config = await widget.configService.loadConfig();

    setState(() {
      _config = config;
      _editorController.text = config.defaultEditor;
      _baseFontSize = config.baseFontSize;
      _isLoading = false;
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

    return editorChanged || themeChanged || fontSizeChanged;
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

    setState(() => _isSaving = true);

    try {
      final updatedConfig = AppConfig(
        directories: _config!.directories,
        defaultEditor: _editorController.text.trim(),
        themeMode: _config!.themeMode,
        baseFontSize: _baseFontSize,
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
                          '${_baseFontSize.toStringAsFixed(0)}',
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

                  Text(
                    'Storage',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notes Directory',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  if (_config != null)
                    ...(_config!.directories.map((dir) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            dir,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ))),
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
