import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../services/config_service.dart';
import '../utils/hotkey_helper.dart';
import '../widgets/note_markdown_viewer.dart';

class EditScreen extends StatefulWidget {
  final NoteService noteService;
  final Note note;

  const EditScreen({
    super.key,
    required this.noteService,
    required this.note,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  final FocusNode _textFocusNode = FocusNode();
  bool _isPreview = false;
  bool _isSaving = false;
  String _originalTitle = '';
  HotkeyConfig _hotkeys = const HotkeyConfig();

  @override
  void initState() {
    super.initState();
    _originalTitle = widget.note.title;
    _titleController = TextEditingController(text: widget.note.title);
    _textController = TextEditingController(text: widget.note.text);
    _loadHotkeys();
    // Request focus on text field after first frame and position cursor at beginning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
      _textController.selection = const TextSelection.collapsed(offset: 0);
    });
  }

  Future<void> _loadHotkeys() async {
    final config = await widget.noteService.configService.loadConfig();
    if (mounted) {
      setState(() {
        _hotkeys = config.hotkeys;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    // Check if title contains reserved characters (reserved for link parameters)
    if (title.contains('?')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title cannot contain ? character'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedNote = widget.note.copyWith(
        title: title,
        text: text,
      );

      await widget.noteService.saveNote(
        updatedNote,
        existingTitle: _originalTitle != title ? _originalTitle : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved')),
        );
        Navigator.pop(context, true); // Return true to indicate save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _togglePreview() {
    setState(() => _isPreview = !_isPreview);
  }

  bool _hasUnsavedChanges() {
    return _titleController.text != widget.note.title ||
        _textController.text != widget.note.text;
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
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Handle Ctrl-P for preview toggle
          final isControlPressed = HardwareKeyboard.instance.isControlPressed;
          final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

          if (event.logicalKey == LogicalKeyboardKey.keyP &&
              (isControlPressed || isMetaPressed)) {
            _togglePreview();
            return KeyEventResult.handled;
          }

          // Handle Ctrl-S to save
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              (isControlPressed || isMetaPressed)) {
            _saveNote();
            return KeyEventResult.handled;
          }

          // Handle navigate back hotkey to close
          if (HotkeyHelper.matches(event, _hotkeys.navigateBack)) {
            _handleClose();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isPreview ? 'Preview' : 'Edit Note'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleClose,
          ),
          actions: [
            IconButton(
              icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
              tooltip: _isPreview ? 'Edit' : 'Preview',
              onPressed: _togglePreview,
            ),
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
                onPressed: _saveNote,
              ),
          ],
        ),
        body: _isPreview ? _buildPreview() : _buildEditor(),
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      primary: false,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'MyNoteName or My Note Name',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Help text
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Markdown Tips:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• CamelCase words auto-link: MyOtherNote',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• Link titles with spaces: [My Note](My Note)',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• Disambiguate: [My Note](My Note?id=xxx)',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• Add tags with #hashtag',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• Use # for headings, ** for bold, * for italic',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• Use - or * for bullet lists',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Text field
          TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            decoration: const InputDecoration(
              labelText: 'Content (Markdown)',
              hintText: 'Start writing...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: null,
            minLines: 15,
            keyboardType: TextInputType.multiline,
            enableInteractiveSelection: true,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          const Divider(),
          const SizedBox(height: 16),

          // Markdown preview
          NoteMarkdownViewer(
            text: text,
            noteTitle: title,
            onNoteLinkTap: (noteTitle) {
              // Note links don't navigate in preview mode, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Link to note: $noteTitle')),
              );
            },
            onTagTap: (tag) {
              // Tag links don't navigate in preview mode, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tag: #$tag')),
              );
            },
          ),
        ],
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
          if (HotkeyHelper.matches(event, const HotkeyConfig().closeDialog)) {
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
