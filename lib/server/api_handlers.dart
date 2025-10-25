import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/note_service.dart';
import '../models/note.dart';

class ApiHandlers {
  final NoteService noteService;

  ApiHandlers(this.noteService);

  Router get router {
    final router = Router();

    // Health check
    router.get('/health', _healthCheck);

    // Notes endpoints
    router.get('/notes', _getAllNotes);
    router.get('/notes/<id>', _getNoteById);
    router.get('/notes/by-title/<title>', _getNotesByTitle);
    router.get('/notes/search', _searchNotes);
    router.post('/notes', _createNote);
    router.put('/notes/<id>', _updateNote);
    router.delete('/notes/<id>', _deleteNote);

    return router;
  }

  Future<Response> _healthCheck(Request request) async {
    return Response.ok(json.encode({'status': 'ok'}),
        headers: {'Content-Type': 'application/json'});
  }

  Map<String, dynamic> _noteToJson(Note note) {
    final map = note.toMap();
    map['text'] = note.text; // Add text field for API
    return map;
  }

  Note _noteFromJson(Map<String, dynamic> json) {
    final text = json['text']?.toString() ?? '';
    return Note.fromMap(json, text);
  }

  Future<Response> _getAllNotes(Request request) async {
    try {
      final notes = await noteService.getAllNotes();
      final jsonList = notes.map((note) => _noteToJson(note)).toList();
      return Response.ok(json.encode(jsonList),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: json.encode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getNoteById(Request request, String id) async {
    try {
      final note = await noteService.getNoteById(id);
      if (note == null) {
        return Response.notFound(json.encode({'error': 'Note not found'}),
            headers: {'Content-Type': 'application/json'});
      }
      return Response.ok(json.encode(_noteToJson(note)),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: json.encode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getNotesByTitle(Request request, String title) async {
    try {
      final notes = await noteService.getNotesByTitle(Uri.decodeComponent(title));
      final jsonList = notes.map((note) => _noteToJson(note)).toList();
      return Response.ok(json.encode(jsonList),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: json.encode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _searchNotes(Request request) async {
    try {
      final query = request.url.queryParameters['q'] ?? '';
      final notes = await noteService.searchNotes(query);
      final jsonList = notes.map((note) => _noteToJson(note)).toList();
      return Response.ok(json.encode(jsonList),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: json.encode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _createNote(Request request) async {
    try {
      final body = await request.readAsString();
      final noteMap = json.decode(body);
      final note = _noteFromJson(noteMap);

      // Use NoteService.createNote which returns a Note
      final createdNote = await noteService.createNote(
        title: note.title,
        text: note.text,
        types: note.types,
        extraFields: note.extraFields,
      );

      return Response(201,
          body: json.encode(_noteToJson(createdNote)),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: json.encode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _updateNote(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final noteMap = json.decode(body);
      final note = _noteFromJson(noteMap);

      if (note.id != id) {
        return Response.badRequest(
            body: json.encode({'error': 'ID mismatch'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Use NoteService.saveNote
      await noteService.saveNote(note);

      // Fetch the updated note to return
      final updatedNote = await noteService.getNoteById(id);
      if (updatedNote == null) {
        return Response.notFound(json.encode({'error': 'Note not found after update'}),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(json.encode(_noteToJson(updatedNote)),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: json.encode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _deleteNote(Request request, String id) async {
    try {
      await noteService.deleteNoteById(id);
      return Response(204); // No content
    } catch (e) {
      return Response.internalServerError(
          body: json.encode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
