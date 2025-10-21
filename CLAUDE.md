# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See README.md for project overview and user-facing features.

## Implementation Details

### Note Service Caching

The NoteService maintains a dual caching system:
- `_noteCache`: Map<String, List<Note>> by title (supports multiple notes with same title)
- `_noteCacheById`: Map<String, Note> by ID (unique lookup)
- `_noteFilePaths`: Map<String, String> by ID to file path

### Link Extraction

`lib/utils/link_extractor.dart` extracts links and tags from text. **Important**:
Self-references (links to the note's own title) must be excluded from `_links`
field. Use `excludeTitle` parameter when calling extraction functions.

### Title Disambiguation

When multiple notes share the same title:
- Navigation shows disambiguation dialog to choose which note to view
- Links can use query string format to specify exact note: `Title?id=xxx`
- Adding a note with existing title opens that note for editing instead of creating duplicate

### Theme Implementation

Theme changes are handled via callback from screens to `main.dart`. Settings
screen tracks theme locally to update SegmentedButton selection immediately.
Theme preference persists via ConfigService.

Unsaved changes detection in SettingsScreen must check both editor field AND
theme mode changes.

### Keyboard Shortcuts

All screens with keyboard shortcuts wrap their Scaffold in a Focus widget with
`onKeyEvent` handler. Use `HardwareKeyboard.instance.isControlPressed` to check
modifiers (not `event.isControlPressed`).

Plus key detection: Check `event.character == '+'` OR `event.logicalKey == LogicalKeyboardKey.add`
to support both Shift+= and numpad +.

### Unsaved Changes Confirmation

Edit and Settings screens check for unsaved changes before closing via Escape or
back button. Pattern:
1. `_hasUnsavedChanges()` - check if fields differ from original
2. `_confirmDiscard()` - show dialog if changes exist
3. `_handleClose()` - call confirmDiscard before Navigator.pop

### Theme-Aware Colors

Help text cards use `Theme.of(context).colorScheme.surfaceContainerHighest` for
background and `colorScheme.onSurface` for text to work in both light and dark modes.
Avoid hardcoded colors like `Colors.blue.shade50`.

## File Structure

### Screens
- `lib/screens/view_screen.dart` - View note with rendered markdown, floating action button
- `lib/screens/edit_screen.dart` - Edit note title and text with preview toggle
- `lib/screens/list_view_screen.dart` - List all notes with search
- `lib/screens/settings_screen.dart` - Configure default editor and theme

### Widgets
- `lib/widgets/note_markdown_viewer.dart` - Shared markdown rendering with link detection
  - Removes duplicate heading if first heading matches note title
  - Converts CamelCase/URLs/hashtags to clickable links

### Utils
- `lib/utils/markdown_link_helper.dart` - Convert patterns to markdown links
  - Uses xdg-open on Linux for URL opening to avoid GTK warnings
- `lib/utils/link_extractor.dart` - Extract links and tags from text

### Services
- `lib/services/note_service.dart` - Note CRUD with dual caching, handles title changes
- `lib/services/config_service.dart` - App configuration and theme persistence

### Models
- `lib/models/note.dart` - Note data model with YAML frontmatter serialization

## Testing

Unit tests in `test/` directory. Main test file is `test/widget_test.dart`.

