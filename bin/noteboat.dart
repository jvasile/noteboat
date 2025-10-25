#!/usr/bin/env dart

import 'dart:io';
import 'package:riverpod/riverpod.dart';
import 'package:noteboat/providers.dart';
import 'package:noteboat/cli/cli_commands.dart';

Future<void> main(List<String> args) async {
  // Handle version and help immediately
  if (args.isEmpty) {
    // No arguments: launch GUI
    await launchGUI();
    return;
  }

  final command = args[0];

  // Handle version and help without initializing services
  if (command == '--version' || command == '-v') {
    printVersion();
    return;
  }

  if (command == 'help' || command == '--help' || command == '-h') {
    printHelp();
    return;
  }

  // Handle serve command separately (doesn't need note service)
  if (command == 'serve') {
    await handleServeCommand(args);
    return;
  }

  // Initialize services using Riverpod
  final container = ProviderContainer();
  try {
    final noteService = container.read(noteServiceProvider);
    await noteService.initialize();

    // Handle commands
    switch (command) {
      case 'list':
        final notes = await noteService.getAllNotes();
        if (notes.isEmpty) {
          print('No notes found.');
        } else {
          print('All notes:');
          for (final note in notes) {
            final tagCount = note.tags.length;
            final linkCount = note.links.length;
            print('  ${note.title}: $tagCount tags, $linkCount links');
          }
        }
        break;
      case 'search':
        if (args.length < 2) {
          print('Usage: noteboat search <query terms...>');
          exit(1);
        }
        final query = args.sublist(1).join(' ');
        final results = await noteService.searchNotes(query);
        if (results.isEmpty) {
          print('No notes found matching: $query');
        } else {
          print('Found ${results.length} note(s):');
          for (final note in results) {
            final preview = note.text.length > 50
                ? '${note.text.substring(0, 50)}...'
                : note.text;
            final cleanPreview = preview.replaceAll('\n', ' ');
            print('  ${note.title}: $cleanPreview');
          }
        }
        break;
      default:
        print('Unknown command: $command');
        printHelp();
        exit(1);
    }
  } finally {
    container.dispose();
  }
}

/// Launch the GUI application
Future<void> launchGUI() async {
  // Find the noteboat-gui executable
  // It should be in the same directory as this CLI executable
  final executable = Platform.resolvedExecutable;
  final executableDir = File(executable).parent.path;
  final guiExecutable = '$executableDir/noteboat-gui';

  try {
    // Launch the GUI and wait for it to complete
    final result = await Process.run(guiExecutable, []);
    exit(result.exitCode);
  } catch (e) {
    print('Error launching GUI: $e');
    print('Make sure noteboat-gui is installed in the same directory.');
    exit(1);
  }
}
