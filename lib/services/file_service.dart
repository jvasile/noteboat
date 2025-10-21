import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/note.dart';

class FileService {
  // Parse a markdown file with YAML frontmatter
  static Future<Note?> readNoteFromFile(String filePath, {bool autoFix = true}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final result = parseNoteContent(content);

      if (result == null) {
        return null;
      }

      final note = result['note'] as Note;
      final wasFixed = result['wasFixed'] as bool;

      // If parsing was fixed and auto-fix is enabled, save corrected version
      if (wasFixed && autoFix) {
        print('Auto-fixing and saving corrected YAML for: $filePath');
        try {
          await writeNoteToFile(note, filePath);
          print('Successfully saved corrected file');
        } catch (e) {
          print('Error writing corrected file: $e');
        }
      }

      return note;
    } catch (e) {
      print('Error reading note from $filePath: $e');
      return null;
    }
  }

  // Parse note content (YAML frontmatter + markdown body)
  // Returns a map with 'note' and 'wasFixed' keys
  static Map<String, dynamic>? parseNoteContent(String content) {
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
      bool wasFixed = false;

      // Fix common YAML issues: empty field values without quotes
      // Only fix lines where the next line is NOT indented (meaning it's truly empty, not a list/map parent)
      final lines = yamlContent.split('\n');
      final fixedLines = <String>[];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final match = RegExp(r'^(\s*)(\w+):\s*$').firstMatch(line);

        if (match != null) {
          // Check if next line is more indented (has children)
          final currentIndent = match.group(1)!.length;
          final hasChildren = i + 1 < lines.length &&
              lines[i + 1].trim().isNotEmpty &&
              lines[i + 1].startsWith(RegExp(r'\s{' + (currentIndent + 1).toString() + r',}'));

          if (!hasChildren) {
            // No children, so it's truly empty - add quotes
            fixedLines.add('${match.group(1)}${match.group(2)}: ""');
            wasFixed = true;
          } else {
            // Has children, leave it alone
            fixedLines.add(line);
          }
        } else {
          fixedLines.add(line);
        }
      }

      if (wasFixed) {
        yamlContent = fixedLines.join('\n');
      }

      // Try to parse YAML
      try {
        final yaml = loadYaml(yamlContent);
        final frontmatter = Map<String, dynamic>.from(yaml);

        // Get markdown body (everything after second ---)
        final body = parts.skip(2).join('---').trim();

        return {
          'note': Note.fromMap(frontmatter, body),
          'wasFixed': wasFixed,
        };
      } catch (yamlError) {
        // Check if error is due to unquoted @ field names
        final errorStr = yamlError.toString();
        if (errorStr.contains('column 1') || errorStr.contains('Unexpected character')) {
          print('YAML parse error, attempting to fix unquoted @ fields...');

          // Fix unquoted @ field names by adding quotes
          final fixedYaml = yamlContent.replaceAllMapped(
            RegExp(r'^(\s*)@(\w+):', multiLine: true),
            (match) => '${match.group(1)}"@${match.group(2)}":',
          );

          // Save the attempted fix for debugging
          if (fixedYaml != yamlContent) {
            print('Applied @ field fixes.');
            print('Fixed YAML:\n$fixedYaml');
          }

          // Try parsing again - if it fails, we'll catch it below
          Map<String, dynamic> frontmatter;
          try {
            final yaml = loadYaml(fixedYaml);
            frontmatter = Map<String, dynamic>.from(yaml);
          } catch (e) {
            print('Still failed to parse after fixing @ fields: $e');
            print('Attempted fix was:\n---\n$fixedYaml\n---');
            rethrow;
          }

          // Get markdown body (everything after second ---)
          final body = parts.skip(2).join('---').trim();

          print('Successfully fixed YAML parsing issue');
          return {
            'note': Note.fromMap(frontmatter, body),
            'wasFixed': true,
          };
        }
        rethrow;
      }
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
