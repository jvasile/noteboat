import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_markdown_viewer.dart';
import 'edit_screen.dart';
import 'list_view_screen.dart';

class ViewScreen extends StatefulWidget {
  final NoteService noteService;
  final String? noteTitle;
  final String? noteId;

  const ViewScreen({
    super.key,
    required this.noteService,
    this.noteTitle,
    this.noteId,
  }) : assert(noteTitle != null || noteId != null, 'Either noteTitle or noteId must be provided');

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  Note? _note;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Note? note;

      if (widget.noteId != null) {
        // Load by ID
        note = await widget.noteService.getNoteById(widget.noteId!);
      } else if (widget.noteTitle != null) {
        // Load by title
        note = await widget.noteService.getNoteByTitle(widget.noteTitle!);
      }

      setState(() {
        _note = note;
        _isLoading = false;
        if (note == null) {
          _error = 'Note not found';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading note: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToNote(String linkText) async {
    // Parse link text - could be "Title" or "Title?id=xxx" or "Title?id=xxx&other=value"
    String title;
    Map<String, String> params = {};

    if (linkText.contains('?')) {
      final parts = linkText.split('?');
      title = parts[0];
      if (parts.length > 1) {
        // Parse query string parameters
        try {
          params = Uri.splitQueryString(parts[1]);
        } catch (e) {
          // Invalid query string, ignore parameters
        }
      }
    } else {
      title = linkText;
    }

    final specifiedId = params['id'];

    // If ID is specified, navigate directly to that note
    if (specifiedId != null) {
      final note = await widget.noteService.getNoteById(specifiedId);
      if (note != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewScreen(
              noteService: widget.noteService,
              noteId: note.id,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note not found: $title?id=$specifiedId')),
        );
      }
      return;
    }

    // No ID specified - check for multiple notes with same title
    final notes = await widget.noteService.getNotesByTitle(title);

    if (!mounted) return;

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note not found: $title')),
      );
    } else if (notes.length == 1) {
      // Only one note with this title - navigate to it
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewScreen(
            noteService: widget.noteService,
            noteId: notes.first.id,
          ),
        ),
      );
    } else {
      // Multiple notes with same title - show disambiguation
      _showDisambiguation(title, notes);
    }
  }

  void _showDisambiguation(String title, List<Note> notes) {
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
                        builder: (context) => ViewScreen(
                          noteService: widget.noteService,
                          noteId: note.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTagList(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListViewScreen(
          noteService: widget.noteService,
          initialSearchQuery: '#$tag',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_note?.title ?? 'Note'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'All Notes',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ListViewScreen(
                    noteService: widget.noteService,
                  ),
                ),
              );
            },
          ),
          if (_note != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditScreen(
                      noteService: widget.noteService,
                      note: _note!,
                    ),
                  ),
                );

                if (result == true) {
                  _loadNote();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Markdown content
                      NoteMarkdownViewer(
                        text: _note!.text,
                        noteTitle: _note!.title,
                        onNoteLinkTap: _navigateToNote,
                        onTagTap: _navigateToTagList,
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Footer metadata
                      Text(
                        'Modified: ${_formatDateTime(_note!.mtime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_note!.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_note!.editors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Editors: ${_note!.editors.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
