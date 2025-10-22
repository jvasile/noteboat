import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';
import 'package:path/path.dart' as path;

/// Widget that embeds a real Neovim instance for editing note content.
///
/// This widget:
/// - Creates a temporary file with the note content
/// - Launches nvim in a PTY
/// - Watches for file changes (when user saves in nvim)
/// - Calls onSave callback when file is modified
/// - Calls onQuit callback when nvim exits (user types :q)
class NvimEditor extends StatefulWidget {
  final String initialContent;
  final Function(String content) onSave;
  final VoidCallback onQuit;

  const NvimEditor({
    super.key,
    required this.initialContent,
    required this.onSave,
    required this.onQuit,
  });

  @override
  State<NvimEditor> createState() => _NvimEditorState();
}

class _NvimEditorState extends State<NvimEditor> {
  late Terminal _terminal;
  late Pty _pty;
  late File _tempFile;
  late String _lastContent;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _lastContent = widget.initialContent;
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    // Create temporary file for editing
    final tempDir = await Directory.systemTemp.createTemp('noteboat_nvim_');
    _tempFile = File(path.join(tempDir.path, 'note.md'));
    await _tempFile.writeAsString(widget.initialContent);

    // Initialize terminal with reasonable max lines
    _terminal = Terminal(
      maxLines: 10000,
    );

    // Create PTY and launch nvim
    _pty = Pty.start(
      'nvim',
      arguments: [_tempFile.path],
      environment: Platform.environment,
    );

    // Listen for terminal resize events and update PTY
    _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      try {
        _pty.resize(height, width);
      } catch (e) {
        // Ignore resize errors
      }
    };

    // Connect PTY output to terminal
    _pty.output.cast<List<int>>().listen((data) {
      if (!_isDisposed) {
        _terminal.write(String.fromCharCodes(data));
      }
    });

    // Connect terminal input to PTY
    _terminal.onOutput = (data) {
      _pty.write(Utf8Encoder().convert(data));
    };

    // Watch for PTY exit (user quit nvim)
    _pty.exitCode.then((exitCode) {
      if (!_isDisposed) {
        _readFinalContent();
        widget.onQuit();
      }
    });

    // Watch for file changes (user saved in nvim)
    _watchFileChanges();

    if (mounted) {
      setState(() {});
    }
  }

  void _watchFileChanges() {
    // Poll file for changes every 500ms
    Future.doWhile(() async {
      if (_isDisposed) return false;

      await Future.delayed(const Duration(milliseconds: 500));

      if (_isDisposed || !await _tempFile.exists()) return false;

      try {
        final currentContent = await _tempFile.readAsString();
        if (currentContent != _lastContent) {
          _lastContent = currentContent;
          widget.onSave(currentContent);
        }
      } catch (e) {
        // File might be temporarily locked during save
      }

      return !_isDisposed;
    });
  }

  Future<void> _readFinalContent() async {
    try {
      if (await _tempFile.exists()) {
        final content = await _tempFile.readAsString();
        if (content != _lastContent) {
          widget.onSave(content);
        }
      }
    } catch (e) {
      // Ignore errors reading final content
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pty.kill();

    // Clean up temp file
    _tempFile.delete().catchError((_) {});
    _tempFile.parent.delete().catchError((_) {});

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TerminalView(
      _terminal,
      textStyle: TerminalStyle(
        fontSize: 14,
        fontFamily: 'monospace',
      ),
      autofocus: true,
      backgroundOpacity: 1.0,
    );
  }
}
