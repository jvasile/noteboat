#!/usr/bin/env dart

import 'dart:io';
import 'package:noteboat/config/config_repository.dart';
import 'package:noteboat/cli/cli_note_service.dart';
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

  // Initialize services for other commands
  final configRepository = ConfigRepository();
  final noteService = CliNoteService(configRepository);
  await noteService.initialize();

  // Handle commands
  switch (command) {
    case 'list':
      await handleListCommand(noteService);
      break;
    case 'search':
      await handleSearchCommand(noteService, args);
      break;
    default:
      print('Unknown command: $command');
      printHelp();
      exit(1);
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
