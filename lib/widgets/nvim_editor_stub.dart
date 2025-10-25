import 'package:flutter/material.dart';

/// Stub version of NvimEditor for platforms that don't support it (web).
///
/// This widget provides the same interface as the real NvimEditor but
/// displays an error message indicating that nvim is not available on this platform.
class NvimEditor extends StatelessWidget {
  final String initialContent;
  final Function(String content) onSave;
  final VoidCallback onQuit;
  final double fontSize;

  const NvimEditor({
    super.key,
    required this.initialContent,
    required this.onSave,
    required this.onQuit,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    // Immediately call onQuit since nvim is not available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onQuit();
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Neovim Editor Not Available',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The Neovim editor mode is not supported on web platforms. '
                'It requires native terminal integration which is only available '
                'on desktop platforms (Linux, macOS, Windows).',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Please use the basic editor mode instead.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
