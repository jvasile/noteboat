import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/note.dart';

class FileService {
  // Parse a markdown file with YAML frontmatter
  static Future<Note?> readNoteFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      return parseNoteContent(content);
    } catch (e) {
      print('Error reading note from $filePath: $e');
      return null;
    }
  }

  // Parse note content (YAML frontmatter + markdown body)
  static Note? parseNoteContent(String content) {
    try {
      // Check if content starts with YAML frontmatter (---)
      if (!content.startsWith('---')) {
        return null;
      }

      // Find the end of frontmatter
      final parts = content.split('---');
      if (parts.length < 3) {
        return null;
      }

      // Parse YAML frontmatter (skip first empty part)
      var yamlContent = parts[1].trim();

      // Fix common YAML issues: empty field values without quotes
      // Replace lines like "author: " or "author:" with "author: ''"
      yamlContent = yamlContent.replaceAllMapped(
        RegExp(r'^(\s*\w+):\s*$', multiLine: true),
        (match) => '${match.group(1)}: ""',
      );

      final yaml = loadYaml(yamlContent);
      final frontmatter = Map<String, dynamic>.from(yaml);

      // Get markdown body (everything after second ---)
      final body = parts.skip(2).join('---').trim();

      return Note.fromMap(frontmatter, body);
    } catch (e) {
      print('Error parsing note content: $e');
      return null;
    }
  }

  // Write note to file with YAML frontmatter
  static Future<void> writeNoteToFile(Note note, String filePath) async {
    try {
      final file = File(filePath);

      // Create parent directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Build YAML frontmatter
      final frontmatter = note.toMap();
      final yamlLines = <String>[];

      for (final entry in frontmatter.entries) {
        var key = entry.key;
        final value = entry.value;

        // Quote keys that start with @ (reserved in YAML)
        if (key.startsWith('@')) {
          key = '"$key"';
        }

        if (value is List) {
          if (value.isEmpty) {
            yamlLines.add('$key: []');
          } else {
            yamlLines.add('$key:');
            for (final item in value) {
              yamlLines.add('  - $item');
            }
          }
        } else if (value is Map) {
          yamlLines.add('$key:');
          for (final subEntry in (value as Map).entries) {
            yamlLines.add('  ${subEntry.key}: ${subEntry.value}');
          }
        } else if (value is String && value.isEmpty) {
          // Handle empty strings properly
          yamlLines.add('$key: ""');
        } else {
          yamlLines.add('$key: $value');
        }
      }

      // Build complete file content
      final fileContent = '''---
${yamlLines.join('\n')}
---

${note.text}
''';

      await file.writeAsString(fileContent);
    } catch (e) {
      print('Error writing note to $filePath: $e');
      rethrow;
    }
  }

  // Get all .md files in a directory (recursive)
  static Future<List<String>> getAllNoteFiles(String directoryPath) async {
    final List<String> noteFiles = [];

    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return noteFiles;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.md')) {
          noteFiles.add(entity.path);
        }
      }
    } catch (e) {
      print('Error listing note files in $directoryPath: $e');
    }

    return noteFiles;
  }

  // Delete a note file
  static Future<void> deleteNoteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting note file $filePath: $e');
      rethrow;
    }
  }
}
