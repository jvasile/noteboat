import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'view_screen.dart';
import 'edit_screen.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
    }
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                builder: (context) => EditScreen(
                  noteService: widget.noteService,
                  note: existingNotes.first,
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
        // Note doesn't exist - create it
        final newNote = await widget.noteService.createNote(
          title: result,
          text: '# $result\n\nStart writing here...',
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
                        builder: (context) => EditScreen(
                          noteService: widget.noteService,
                          note: note,
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
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Handle '+' key for add note
          if (event.character == '+' || event.logicalKey == LogicalKeyboardKey.add) {
            _handleAddNoteShortcut();
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
                fillColor: Colors.white,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddNoteShortcut,
        child: const Icon(Icons.add),
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
            hintText: 'Note title (CamelCase)',
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
