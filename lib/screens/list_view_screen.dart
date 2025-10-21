import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'view_screen.dart';
import 'settings_screen.dart';

class ListViewScreen extends StatefulWidget {
  final NoteService noteService;

  const ListViewScreen({super.key, required this.noteService});

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
      _filteredNotes = notes;
      _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        onPressed: () async {
          final result = await _showCreateNoteDialog();
          if (result != null && result.isNotEmpty) {
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
                  ),
                ),
              );
            }
          }
        },
        child: const Icon(Icons.add),
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
