import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import 'note_service_interface.dart';

/// HTTP client implementation of note service for web builds
class NoteServiceHttp implements INoteService {
  final String baseUrl;
  final String? authToken;
  bool _initialized = false;

  NoteServiceHttp({
    required this.baseUrl,
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  @override
  Future<void> initialize() async {
    // Check if server is reachable
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        _initialized = true;
      } else {
        throw Exception('Server not reachable: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Note _noteFromJson(Map<String, dynamic> jsonMap) {
    final text = jsonMap['text']?.toString() ?? '';
    return Note.fromMap(jsonMap, text);
  }

  Map<String, dynamic> _noteToJson(Note note) {
    final map = note.toMap();
    map['text'] = note.text;
    return map;
  }

  @override
  Future<List<Note>> getAllNotes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notes'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => _noteFromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch notes: ${response.statusCode}');
    }
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notes/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _noteFromJson(json.decode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch note: ${response.statusCode}');
    }
  }

  @override
  Future<Note?> getNoteByTitle(String title) async {
    final notes = await getNotesByTitle(title);
    return notes.isNotEmpty ? notes.first : null;
  }

  @override
  Future<List<Note>> getNotesByTitle(String title) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notes/by-title/${Uri.encodeComponent(title)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => _noteFromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch notes by title: ${response.statusCode}');
    }
  }

  @override
  Future<Note> createNote({
    required String title,
    String text = '',
    List<String>? types,
    Map<String, dynamic>? extraFields,
  }) async {
    final note = Note(
      id: '', // Server will generate ID
      title: title,
      text: text,
      mtime: DateTime.now(),
      editors: [],
      types: types,
      extraFields: extraFields,
    );

    final response = await http.post(
      Uri.parse('$baseUrl/api/notes'),
      headers: _headers,
      body: json.encode(_noteToJson(note)),
    );

    if (response.statusCode == 201) {
      return _noteFromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create note: ${response.statusCode}');
    }
  }

  @override
  Future<void> saveNote(Note note, {String? existingTitle}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notes/${note.id}'),
      headers: _headers,
      body: json.encode(_noteToJson(note)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update note: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteNoteById(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notes/$id'),
      headers: _headers,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete note: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteNote(String title) async {
    final note = await getNoteByTitle(title);
    if (note != null) {
      await deleteNoteById(note.id);
    }
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notes/search?q=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => _noteFromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to search notes: ${response.statusCode}');
    }
  }

  @override
  Future<List<Note>> getNotesByTag(String tag) async {
    // Use search as a fallback - server doesn't have dedicated tag endpoint
    final allNotes = await getAllNotes();
    final lowerTag = tag.toLowerCase();
    return allNotes.where((note) =>
      note.tags.any((t) => t.toLowerCase() == lowerTag)
    ).toList();
  }

  @override
  Future<bool> noteExists(String title) async {
    final notes = await getNotesByTitle(title);
    return notes.isNotEmpty;
  }

  @override
  Future<void> reload() async {
    // No-op for HTTP client - always fetches fresh data
  }
}
