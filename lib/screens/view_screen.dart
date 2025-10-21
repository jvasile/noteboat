import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_markdown_viewer.dart';
import 'edit_screen.dart';
import 'list_view_screen.dart';

class ViewScreen extends StatefulWidget {
  final NoteService noteService;
  final String noteTitle;

  const ViewScreen({
    super.key,
    required this.noteService,
    required this.noteTitle,
  });

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
      final note = await widget.noteService.getNoteByTitle(widget.noteTitle);

      setState(() {
        _note = note;
        _isLoading = false;
        if (note == null) {
          _error = 'Note "${widget.noteTitle}" not found';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading note: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToNote(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewScreen(
          noteService: widget.noteService,
          noteTitle: title,
        ),
      ),
    );
  }

  void _navigateToTagList(String tag) async {
    final notes = await widget.noteService.getNotesByTag(tag);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Notes with tag #$tag',
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
                  subtitle: Text(
                    note.text.length > 50
                        ? '${note.text.substring(0, 50)}...'
                        : note.text,
                    maxLines: 1,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToNote(note.title);
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
                      // Title
                      Text(
                        _note!.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Metadata
                      Text(
                        'Modified: ${_formatDateTime(_note!.mtime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_note!.editors.isNotEmpty) ...[
                        Text(
                          'Editors: ${_note!.editors.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Tags
                      if (_note!.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _note!.tags.map((tag) {
                            return ActionChip(
                              label: Text('#$tag'),
                              onPressed: () => _navigateToTagList(tag),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Divider(),
                      const SizedBox(height: 16),

                      // Markdown content
                      NoteMarkdownViewer(
                        text: _note!.text,
                        noteTitle: _note!.title,
                        onNoteLinkTap: _navigateToNote,
                      ),
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
