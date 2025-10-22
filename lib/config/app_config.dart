/// Shared configuration models (pure Dart, no Flutter dependencies)
/// Used by both GUI and CLI

/// Hotkey configuration for the application
class HotkeyConfig {
  final String newNote;
  final String search;
  final String editNote;
  final String viewMode;
  final String navigateBack;
  final String moveUp;
  final String moveDown;
  final String closeDialog;

  const HotkeyConfig({
    this.newNote = '+,Add',
    this.search = '/',
    this.editNote = 'e',
    this.viewMode = 'v',
    this.navigateBack = 'Escape,Alt+ArrowLeft',
    this.moveUp = 'ArrowUp,k',
    this.moveDown = 'ArrowDown,j',
    this.closeDialog = 'Escape',
  });

  factory HotkeyConfig.fromMap(Map<String, dynamic> map) {
    return HotkeyConfig(
      newNote: map['newNote']?.toString() ?? '+,Add',
      search: map['search']?.toString() ?? '/',
      editNote: map['editNote']?.toString() ?? 'e',
      viewMode: map['viewMode']?.toString() ?? 'v',
      navigateBack: map['navigateBack']?.toString() ?? 'Escape,Alt+ArrowLeft',
      moveUp: map['moveUp']?.toString() ?? 'ArrowUp,k',
      moveDown: map['moveDown']?.toString() ?? 'ArrowDown,j',
      closeDialog: map['closeDialog']?.toString() ?? 'Escape',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'newNote': newNote,
      'search': search,
      'editNote': editNote,
      'viewMode': viewMode,
      'navigateBack': navigateBack,
      'moveUp': moveUp,
      'moveDown': moveDown,
      'closeDialog': closeDialog,
    };
  }
}

class AppConfig {
  final List<String> directories;
  final String defaultEditor;
  final String themeMode; // 'light', 'dark', or 'system'
  final double baseFontSize; // Base font size for markdown content
  final HotkeyConfig hotkeys;
  final String editorMode; // 'basic' or 'nvim' (nvim only available on Linux/macOS)
  final double nvimFontSize; // Font size for nvim terminal

  AppConfig({
    required this.directories,
    this.defaultEditor = '',
    this.themeMode = 'system',
    this.baseFontSize = 16.0,
    this.hotkeys = const HotkeyConfig(),
    this.editorMode = 'basic',
    this.nvimFontSize = 16.0,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    // Handle both 'defaultEditor' and old 'defaultAuthor' for backward compatibility
    String editor = '';
    if (map['defaultEditor'] != null) {
      editor = map['defaultEditor']?.toString() ?? '';
    } else if (map['defaultAuthor'] != null) {
      editor = map['defaultAuthor']?.toString() ?? '';
    }

    // Parse font size, default to 16.0
    double fontSize = 16.0;
    if (map['baseFontSize'] != null) {
      final fontSizeValue = map['baseFontSize'];
      if (fontSizeValue is num) {
        fontSize = fontSizeValue.toDouble();
      }
    }

    // Parse hotkeys if present
    HotkeyConfig hotkeys = const HotkeyConfig();
    if (map['hotkeys'] != null && map['hotkeys'] is Map) {
      hotkeys = HotkeyConfig.fromMap(Map<String, dynamic>.from(map['hotkeys']));
    }

    // Parse editorMode if present
    String editorMode = map['editorMode']?.toString() ?? 'basic';
    // Validate editorMode value
    if (editorMode != 'basic' && editorMode != 'nvim') {
      editorMode = 'basic';
    }

    // Parse nvimFontSize if present
    double nvimFontSize = 16.0;
    if (map['nvimFontSize'] != null) {
      final nvimFontSizeValue = map['nvimFontSize'];
      if (nvimFontSizeValue is num) {
        nvimFontSize = nvimFontSizeValue.toDouble();
      }
    }

    return AppConfig(
      directories: (map['directories'] as List?)?.map((e) => e.toString()).toList() ?? [],
      defaultEditor: editor,
      themeMode: map['themeMode']?.toString() ?? 'system',
      baseFontSize: fontSize,
      hotkeys: hotkeys,
      editorMode: editorMode,
      nvimFontSize: nvimFontSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'directories': directories,
      'defaultEditor': defaultEditor,
      'themeMode': themeMode,
      'baseFontSize': baseFontSize,
      'hotkeys': hotkeys.toMap(),
      'editorMode': editorMode,
      'nvimFontSize': nvimFontSize,
    };
  }
}
