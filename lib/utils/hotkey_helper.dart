import 'package:flutter/services.dart';

class HotkeyHelper {
  /// Checks if a KeyEvent matches any of the hotkey definitions
  /// Hotkey format: "key" or "Modifier+key" or "key1,key2,Modifier+key3"
  /// Examples: "+", "Escape", "Alt+ArrowLeft", "Escape,Alt+ArrowLeft"
  static bool matches(KeyEvent event, String hotkeyDefinition) {
    if (event is! KeyDownEvent) return false;

    final hotkeys = hotkeyDefinition.split(',').map((s) => s.trim()).toList();

    for (final hotkey in hotkeys) {
      if (_matchesSingleHotkey(event, hotkey)) {
        return true;
      }
    }

    return false;
  }

  static bool _matchesSingleHotkey(KeyEvent event, String hotkey) {
    // Special case: if the hotkey is just "+", don't split it
    // Otherwise "+" would split into empty parts
    if (hotkey == '+') {
      return _matchesKey(event, '+',
        requiresCtrl: false,
        requiresAlt: false,
        requiresMeta: false,
        requiresShift: false);
    }

    // Parse modifier + key combinations
    final parts = hotkey.split('+').map((s) => s.trim()).toList();

    bool requiresCtrl = false;
    bool requiresAlt = false;
    bool requiresShift = false;
    bool requiresMeta = false;
    String? keyPart;

    for (final part in parts) {
      if (part == 'Ctrl' || part == 'Control') {
        requiresCtrl = true;
      } else if (part == 'Alt') {
        requiresAlt = true;
      } else if (part == 'Shift') {
        requiresShift = true;
      } else if (part == 'Meta' || part == 'Cmd') {
        requiresMeta = true;
      } else {
        keyPart = part;
      }
    }

    // Check required modifiers (must be present if specified)
    if (requiresCtrl && !HardwareKeyboard.instance.isControlPressed) return false;
    if (requiresAlt && !HardwareKeyboard.instance.isAltPressed) return false;
    if (requiresShift && !HardwareKeyboard.instance.isShiftPressed) return false;
    if (requiresMeta && !HardwareKeyboard.instance.isMetaPressed) return false;

    // If no modifiers are explicitly required (e.g., just "+" or "e"),
    // we should NOT reject if Ctrl/Alt/Meta are pressed, but we SHOULD
    // reject if they are pressed (for keys that aren't character-based).
    // We'll let _matchesKey handle character matching which naturally
    // works with Shift for symbols.

    // If no key part specified, just match modifiers
    if (keyPart == null || keyPart.isEmpty) return false;

    // Check if key matches
    return _matchesKey(event, keyPart,
      requiresCtrl: requiresCtrl,
      requiresAlt: requiresAlt,
      requiresMeta: requiresMeta,
      requiresShift: requiresShift);
  }

  static bool _matchesKey(KeyEvent event, String keyString, {
    bool requiresCtrl = false,
    bool requiresAlt = false,
    bool requiresMeta = false,
    bool requiresShift = false,
  }) {
    // Handle special keys
    final logicalKeyMap = <String, LogicalKeyboardKey>{
      'Escape': LogicalKeyboardKey.escape,
      'Enter': LogicalKeyboardKey.enter,
      'Tab': LogicalKeyboardKey.tab,
      'Space': LogicalKeyboardKey.space,
      'ArrowUp': LogicalKeyboardKey.arrowUp,
      'ArrowDown': LogicalKeyboardKey.arrowDown,
      'ArrowLeft': LogicalKeyboardKey.arrowLeft,
      'ArrowRight': LogicalKeyboardKey.arrowRight,
      'Backspace': LogicalKeyboardKey.backspace,
      'Delete': LogicalKeyboardKey.delete,
      'Home': LogicalKeyboardKey.home,
      'End': LogicalKeyboardKey.end,
      'PageUp': LogicalKeyboardKey.pageUp,
      'PageDown': LogicalKeyboardKey.pageDown,
      'Add': LogicalKeyboardKey.add,  // Numpad +
    };

    // Check if it's a known logical key
    if (logicalKeyMap.containsKey(keyString)) {
      // For logical keys, reject if unintended modifiers are pressed
      // (unless those modifiers were explicitly required)
      final hasUnwantedModifiers =
        (!requiresCtrl && HardwareKeyboard.instance.isControlPressed) ||
        (!requiresAlt && HardwareKeyboard.instance.isAltPressed) ||
        (!requiresMeta && HardwareKeyboard.instance.isMetaPressed);

      if (hasUnwantedModifiers) return false;
      return event.logicalKey == logicalKeyMap[keyString];
    }

    // For single characters, check character match (this naturally handles Shift)
    if (keyString.length == 1) {
      // For character matching, we want to match the actual character produced
      // regardless of Shift (e.g., "+" matches Shift+= because it produces "+")
      // But we still want to reject Ctrl/Alt/Meta if they weren't required
      final hasUnwantedModifiers =
        (!requiresCtrl && HardwareKeyboard.instance.isControlPressed) ||
        (!requiresAlt && HardwareKeyboard.instance.isAltPressed) ||
        (!requiresMeta && HardwareKeyboard.instance.isMetaPressed);

      if (hasUnwantedModifiers) return false;

      // Check character match - prioritize this for symbols
      if (event.character != null && event.character == keyString) {
        return true;
      }

      // For letters, do case-insensitive match
      if (event.character != null &&
          event.character!.toLowerCase() == keyString.toLowerCase()) {
        return true;
      }

      // Also check logical key for letters
      final char = keyString.toLowerCase();
      if (char.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
          char.codeUnitAt(0) <= 'z'.codeUnitAt(0)) {
        try {
          final logicalKey = LogicalKeyboardKey.findKeyByKeyId(
            0x00000000061 + (char.codeUnitAt(0) - 'a'.codeUnitAt(0))
          );
          if (logicalKey != null && event.logicalKey == logicalKey) {
            return true;
          }
        } catch (e) {
          // Fall through
        }
      }
    }

    return false;
  }
}
