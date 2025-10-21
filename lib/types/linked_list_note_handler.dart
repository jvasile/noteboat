import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_markdown_viewer.dart';
import 'note_type_handler.dart';

/// Helper functions for linked list note fields

String? getLinkedListPrevious(Note note) {
  return note.extraFields['previous']?.toString();
}

String? getLinkedListNext(Note note) {
  return note.extraFields['next']?.toString();
}

Note setLinkedListPrevious(Note note, String? previous) {
  final newExtraFields = Map<String, dynamic>.from(note.extraFields);
  if (previous == null || previous.isEmpty) {
    newExtraFields.remove('previous');
  } else {
    newExtraFields['previous'] = previous;
  }
  return note.copyWith(extraFields: newExtraFields);
}

Note setLinkedListNext(Note note, String? next) {
  final newExtraFields = Map<String, dynamic>.from(note.extraFields);
  if (next == null || next.isEmpty) {
    newExtraFields.remove('next');
  } else {
    newExtraFields['next'] = next;
  }
  return note.copyWith(extraFields: newExtraFields);
}

/// Handler for linked list note type
class LinkedListNoteHandler extends NoteTypeHandler {
  // Auto-register this handler
  static final registered = _register();
  static bool _register() {
    NoteTypeRegistry.instance.register('linked_list_note', LinkedListNoteHandler());
    return true;
  }

  @override
  Widget buildViewer({
    required BuildContext context,
    required Note note,
    required NoteService noteService,
    required Function(String) onNoteLinkTap,
    required Function(String) onTagTap,
    required VoidCallback onRefresh,
    double baseFontSize = 16.0,
  }) {
    return _LinkedListNoteViewer(
      note: note,
      onNoteLinkTap: onNoteLinkTap,
      onTagTap: onTagTap,
      baseFontSize: baseFontSize,
    );
  }

  @override
  Widget buildEditor({
    required BuildContext context,
    required Note note,
    required NoteService noteService,
    required Function(bool) onComplete,
  }) {
    return _LinkedListNoteEditor(
      note: note,
      noteService: noteService,
      onComplete: onComplete,
    );
  }

  @override
  KeyEventResult handleKeyEvent({
    required Note note,
    required KeyEvent event,
    required Function(String) onNoteLinkTap,
  }) {
    if (event is KeyDownEvent) {
      final previous = getLinkedListPrevious(note);
      final next = getLinkedListNext(note);

      // Left arrow -> previous note
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && previous != null) {
        onNoteLinkTap(previous);
        return KeyEventResult.handled;
      }
      // Right arrow -> next note
      if (event.logicalKey == LogicalKeyboardKey.arrowRight && next != null) {
        onNoteLinkTap(next);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}

/// Viewer widget for linked list notes
class _LinkedListNoteViewer extends StatefulWidget {
  final Note note;
  final Function(String) onNoteLinkTap;
  final Function(String) onTagTap;
  final double baseFontSize;

  const _LinkedListNoteViewer({
    required this.note,
    required this.onNoteLinkTap,
    required this.onTagTap,
    this.baseFontSize = 16.0,
  });

  @override
  State<_LinkedListNoteViewer> createState() => _LinkedListNoteViewerState();
}

class _LinkedListNoteViewerState extends State<_LinkedListNoteViewer> {
  final GlobalKey _contentKey = GlobalKey();
  bool _showTopButtons = false;

  @override
  void initState() {
    super.initState();
    // Check content height after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkContentHeight();
    });
  }

  void _checkContentHeight() {
    final RenderBox? renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      final contentHeight = renderBox.size.height;
      final screenHeight = MediaQuery.of(context).size.height;
      setState(() {
        _showTopButtons = contentHeight > screenHeight * 0.8; // Show if content is taller than 80% of screen
      });
    }
  }

  Widget _buildNavigationButtons(String? previous, String? next) {
    return Row(
      children: [
        if (previous != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => widget.onNoteLinkTap(previous),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'Previous: $previous',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (previous != null && next != null)
          const SizedBox(width: 8),
        if (next != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => widget.onNoteLinkTap(next),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                'Next: $next',
                overflow: TextOverflow.ellipsis,
              ),
              iconAlignment: IconAlignment.end,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final previous = getLinkedListPrevious(widget.note);
    final next = getLinkedListNext(widget.note);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Previous/Next navigation buttons at top (only if content is long)
        if (_showTopButtons && (previous != null || next != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildNavigationButtons(previous, next),
          ),

        // Standard markdown content
        Container(
          key: _contentKey,
          child: NoteMarkdownViewer(
            text: widget.note.text,
            noteTitle: widget.note.title,
            onNoteLinkTap: widget.onNoteLinkTap,
            onTagTap: widget.onTagTap,
            baseFontSize: widget.baseFontSize,
          ),
        ),

        // Previous/Next navigation buttons at bottom (always shown above footer)
        if (previous != null || next != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildNavigationButtons(previous, next),
          ),
      ],
    );
  }
}

/// Editor widget for linked list notes
class _LinkedListNoteEditor extends StatefulWidget {
  final Note note;
  final NoteService noteService;
  final Function(bool) onComplete;

  const _LinkedListNoteEditor({
    required this.note,
    required this.noteService,
    required this.onComplete,
  });

  @override
  State<_LinkedListNoteEditor> createState() => _LinkedListNoteEditorState();
}

class _LinkedListNoteEditorState extends State<_LinkedListNoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  late TextEditingController _previousController;
  late TextEditingController _nextController;
  bool _isPreview = false;
  bool _isSaving = false;
  String _originalTitle = '';

  @override
  void initState() {
    super.initState();
    _originalTitle = widget.note.title;
    _titleController = TextEditingController(text: widget.note.title);
    _textController = TextEditingController(text: widget.note.text);
    _previousController = TextEditingController(text: getLinkedListPrevious(widget.note) ?? '');
    _nextController = TextEditingController(text: getLinkedListNext(widget.note) ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _previousController.dispose();
    _nextController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    final previous = _previousController.text.trim();
    final next = _nextController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    if (title.contains('?')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot contain ? character')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      var updatedNote = widget.note.copyWith(
        title: title,
        text: text,
      );

      // Update previous and next fields
      updatedNote = setLinkedListPrevious(updatedNote, previous.isEmpty ? null : previous);
      updatedNote = setLinkedListNext(updatedNote, next.isEmpty ? null : next);

      await widget.noteService.saveNote(
        updatedNote,
        existingTitle: _originalTitle != title ? _originalTitle : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved')),
        );
        widget.onComplete(true);
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
        _textController.text != widget.note.text ||
        _previousController.text != (getLinkedListPrevious(widget.note) ?? '') ||
        _nextController.text != (getLinkedListNext(widget.note) ?? '');
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
        widget.onComplete(false);
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

          if (event.logicalKey == LogicalKeyboardKey.keyP &&
              (isControlPressed || isMetaPressed)) {
            _togglePreview();
            return KeyEventResult.handled;
          }

          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              (isControlPressed || isMetaPressed)) {
            _saveNote();
            return KeyEventResult.handled;
          }

          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _handleClose();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isPreview ? 'Preview' : 'Edit Linked List Note'),
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

          // Previous note field
          TextField(
            controller: _previousController,
            decoration: const InputDecoration(
              labelText: 'Previous Note',
              hintText: 'Title of previous note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Next note field
          TextField(
            controller: _nextController,
            decoration: const InputDecoration(
              labelText: 'Next Note',
              hintText: 'Title of next note (optional)',
              border: OutlineInputBorder(),
            ),
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
                    'Linked List Note:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• This note type creates a sequence of notes',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• Previous/Next buttons will appear in the viewer',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• Enter note titles for previous/next',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    '• For non-unique titles, use: Title?id=xxx',
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
    final previous = _previousController.text.trim();
    final next = _nextController.text.trim();

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

          // Previous/Next navigation preview
          if (previous.isNotEmpty || next.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  if (previous.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Link to note: $previous')),
                          );
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: Text(
                          'Previous: $previous',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  if (previous.isNotEmpty && next.isNotEmpty)
                    const SizedBox(width: 8),
                  if (next.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Link to note: $next')),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          'Next: $next',
                          overflow: TextOverflow.ellipsis,
                        ),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                ],
              ),
            ),

          // Markdown preview
          NoteMarkdownViewer(
            text: text,
            noteTitle: title,
            onNoteLinkTap: (noteTitle) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Link to note: $noteTitle')),
              );
            },
            onTagTap: (tag) {
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
