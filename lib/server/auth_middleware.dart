import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

class AuthMiddleware {
  final String? passwordHash;

  AuthMiddleware({String? password})
      : passwordHash = password != null ? _hashPassword(password) : null;

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Middleware get handler {
    return (Handler innerHandler) {
      return (Request request) async {
        // If no password is set, allow all requests
        if (passwordHash == null) {
          return innerHandler(request);
        }

        // Allow health check without auth
        if (request.url.path == 'api/health') {
          return innerHandler(request);
        }

        // Check for Bearer token
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.unauthorized(
            json.encode({'error': 'Missing or invalid authorization header'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final token = authHeader.substring(7); // Remove 'Bearer ' prefix
        final tokenHash = _hashPassword(token);

        if (tokenHash != passwordHash) {
          return Response.forbidden(
            json.encode({'error': 'Invalid credentials'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        return innerHandler(request);
      };
    };
  }
}
