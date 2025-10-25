import 'note_service_http.dart';
import 'note_service_interface.dart';
import 'config_service.dart';

/// Web implementation - uses HTTP client to communicate with server
INoteService createNoteServiceImpl() {
  // On web, the client is served from the same origin as the API
  // Use relative URL to access the API on the same server
  final baseUrl = ''; // Empty string means same origin

  // TODO: Get auth token from login
  // For now, we'll use a default password for testing
  // In production, there should be a login screen
  final authToken = 'testpass'; // TODO: Get from login screen

  return NoteServiceHttp(
    baseUrl: baseUrl,
    authToken: authToken,
  );
}

/// Web doesn't use local config - return a stub
ConfigService createConfigServiceImpl() {
  return ConfigService();
}
