import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../types/types.dart';
import 'view_screen.dart';
import 'settings_screen.dart';

class ListViewScreen extends StatefulWidget {
  final NoteService noteService;
  final String? initialSearchQuery;
  final Function(ThemeMode)? onThemeChanged;
  final ThemeMode? currentThemeMode;

  const ListViewScreen({
    super.key,
    required this.noteService,
    this.initialSearchQuery,
    this.onThemeChanged,
    this.currentThemeMode,
  });

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
    }
    _loadNotes();
    // Request focus on search field after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    final notes = await widget.noteService.getAllNotes();

    setState(() {
      _notes = notes;
      _isLoading = false;
      // Apply initial search filter if provided
      if (_searchQuery.isNotEmpty) {
        _filterNotes(_searchQuery);
      } else {
        _filteredNotes = notes;
      }
    });
  }

  void _filterNotes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredNotes = _notes.where((note) {
          return note.title.toLowerCase().contains(lowerQuery) ||
              note.text.toLowerCase().contains(lowerQuery) ||
              note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
      }
    });
  }

  void _handleAddNoteShortcut() async {
    await _handleAddNoteWithType('note');
  }

  Future<void> _handleAddNoteWithType(String noteType) async {
    final result = await _showCreateNoteDialog();
    if (result != null && result.isNotEmpty) {
      // Check if note(s) with this title already exist
      final existingNotes = await widget.noteService.getNotesByTitle(result);

      if (existingNotes.isNotEmpty) {
        // Note(s) with this title already exist
        if (mounted) {
          if (existingNotes.length == 1) {
            // Only one note - navigate to edit it
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteTypeRegistry.instance
                    .getHandler(existingNotes.first.types)
                    .buildEditor(
                      context: context,
                      note: existingNotes.first,
                      noteService: widget.noteService,
                      onComplete: (saved) => Navigator.pop(context, saved),
                    ),
              ),
            ).then((result) {
              if (result == true) {
                _loadNotes();
              }
            });
          } else {
            // Multiple notes with same title - show disambiguation for editing
            _showDisambiguationForEdit(result, existingNotes);
          }
        }
      } else {
        // Note doesn't exist - create it with specified type
        final newNote = await widget.noteService.createNote(
          title: result,
          text: '# $result\n\nStart writing here...',
          types: [noteType],
        );
        _loadNotes();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewScreen(
                noteService: widget.noteService,
                noteId: newNote.id,
                onThemeChanged: widget.onThemeChanged,
                currentThemeMode: widget.currentThemeMode,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _showNoteTypeSelector() async {
    final types = NoteTypeRegistry.instance.getRegisteredTypes();

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _NoteTypeSelectorDialog(types: types),
    );

    if (selected != null) {
      await _handleAddNoteWithType(selected);
    }
  }

  void _showDisambiguationForEdit(String title, List<Note> notes) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Multiple notes titled "$title"',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${note.id.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        note.text.length > 50
                            ? '${note.text.substring(0, 50)}...'
                            : note.text,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteTypeRegistry.instance
                            .getHandler(note.types)
                            .buildEditor(
                              context: context,
                              note: note,
                              noteService: widget.noteService,
                              onComplete: (saved) => Navigator.pop(context, saved),
                            ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadNotes();
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Handle '+' key for add note - show type selector
          if (event.character == '+' || event.logicalKey == LogicalKeyboardKey.add) {
            _showNoteTypeSelector();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Notes'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      configService: widget.noteService.configService,
                      onThemeChanged: widget.onThemeChanged,
                      currentThemeMode: widget.currentThemeMode,
                    ),
                  ),
                );
              },
            ),
          ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterNotes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: _filterNotes,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotes.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No notes yet'
                        : 'No notes match your search',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  child: ListView.builder(
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.text.length > 100
                                    ? '${note.text.substring(0, 100)}...'
                                    : note.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (note.tags.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  children: note.tags
                                      .take(3)
                                      .map((tag) => Chip(
                                            label: Text(
                                              '#$tag',
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            padding: EdgeInsets.zero,
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                          trailing: Text(
                            _formatDate(note.mtime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewScreen(
                                  noteService: widget.noteService,
                                  noteId: note.id,
                                  onThemeChanged: widget.onThemeChanged,
                                  currentThemeMode: widget.currentThemeMode,
                                ),
                              ),
                            );
                            // Reload notes when returning
                            _loadNotes();
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: GestureDetector(
        onLongPress: _showNoteTypeSelector,
        child: FloatingActionButton(
          onPressed: _handleAddNoteShortcut,
          tooltip: 'Add Note (long press for type selection)',
          child: const Icon(Icons.add),
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<String?> _showCreateNoteDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Note title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// Keyboard-navigable note type selector dialog
class _NoteTypeSelectorDialog extends StatefulWidget {
  final List<String> types;

  const _NoteTypeSelectorDialog({required this.types});

  @override
  State<_NoteTypeSelectorDialog> createState() => _NoteTypeSelectorDialogState();
}

class _NoteTypeSelectorDialogState extends State<_NoteTypeSelectorDialog> {
  int _selectedIndex = 0;

  void _selectType() {
    Navigator.pop(context, widget.types[_selectedIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _selectedIndex = (_selectedIndex + 1) % widget.types.length;
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _selectedIndex = (_selectedIndex - 1 + widget.types.length) % widget.types.length;
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _selectType();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: const Text('Select Note Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.types.length, (index) {
            final type = widget.types[index];
            final isSelected = index == _selectedIndex;
            return Container(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
              child: ListTile(
                title: Text(
                  NoteTypeRegistry.instance.getTypeName(type),
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                  ),
                ),
                onTap: () => Navigator.pop(context, type),
                selected: isSelected,
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
