import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../services/note_service.dart';

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
  late TextEditingController _authorController;
  bool _isPreview = false;
  bool _isSaving = false;
  String _originalTitle = '';

  @override
  void initState() {
    super.initState();
    _originalTitle = widget.note.title;
    _titleController = TextEditingController(text: widget.note.title);
    _textController = TextEditingController(text: widget.note.text);
    _authorController = TextEditingController(text: widget.note.author);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    final author = _authorController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    // Check if title contains spaces
    if (title.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title should be one word (use CamelCase)'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedNote = widget.note.copyWith(
        title: title,
        text: text,
        author: author,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPreview ? 'Preview' : 'Edit Note'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
            tooltip: _isPreview ? 'Edit' : 'Preview',
            onPressed: () {
              setState(() => _isPreview = !_isPreview);
            },
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
              labelText: 'Title (CamelCase)',
              hintText: 'MyNoteName',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Author field
          TextField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Help text
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Markdown Tips:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• Use CamelCase words to create links: MyOtherNote'),
                  Text('• Add tags with #hashtag'),
                  Text('• Use # for headings, ** for bold, * for italic'),
                  Text('• Use - or * for bullet lists'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _titleController.text.trim(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Author
          if (_authorController.text.trim().isNotEmpty) ...[
            Text(
              'Author: ${_authorController.text.trim()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // Markdown preview
          MarkdownBody(
            data: _textController.text.trim(),
            selectable: true,
          ),
        ],
      ),
    );
  }
}
