# Noteboat

Noteboat is a linked note-taking application built with Flutter. It allows
creation, editing, browsing, and searching of notes with automatic link
detection and rendering.

## Features

- **Automatic Link Detection**: CamelCase words, markdown links, and hashtags are automatically made clickable
- **Multiple Link Formats**: Support for simple titles, titles with spaces, and query string disambiguation
- **Full-Text Search**: Search across all note fields with case-insensitive matching
- **Dark Mode**: Light, dark, and system theme modes with persistence
- **Keyboard Shortcuts**: Efficient keyboard navigation (see below)
- **Note Disambiguation**: Handle multiple notes with the same title gracefully
- **CLI Mode**: Command-line interface for listing and searching notes
- **Markdown Support**: Full markdown rendering with preview mode

## Architecture

### Data Storage

Notes are stored as `.md` files with YAML frontmatter containing metadata:
- `title`: Note title (can be CamelCase or contain spaces)
- `mtime`: Modification time
- `editors`: List of editor names
- `@id`: Unique GUID for the note
- `@type`: Hierarchical type information
- `_links`: Cached list of links (auto-generated, excludes self-references)
- `_tags`: Cached list of tags (auto-generated)

The markdown body contains the note text. The system can also read/write JSON or
other formats if found.

Noteboat searches multiple directories for notes. The directory hierarchy is not
semantically significant - notes are identified by title and @id. Storage
operations use the first configured directory for writes.

### Note Types

Object types fit into a hierarchical type tree. The base type is `note` which
contains title, text, tags, mtime, and links. Additional types can inherit from
the base note and add extra fields.

### Dual Caching System

The NoteService maintains efficient caches:
- By title (supports multiple notes with same title)
- By ID (unique lookup)
- ID to file path mapping

### Link Detection

Links and tags are automatically detected and made clickable:
- **CamelCase**: `MyOtherNote` becomes a clickable link
- **Markdown**: `[My Note](My Note)` for titles with spaces
- **Disambiguation**: `[My Note](My Note?id=xxx)` to specify exact note
- **Hashtags**: `#tagname` links to search results
- **URLs**: `http://` and `https://` links open in browser

## User Interface

### Screens

1. **List View**: Shows all notes with search functionality
2. **View Mode**: Displays note with rendered markdown, clickable links/tags
3. **Edit Mode**: Form for editing title and text with live preview
4. **Settings**: Configure default editor name and theme

### Navigation

- Clicking a note in the list opens it in View mode
- Clicking a link navigates to that note
- Clicking a tag navigates to search results
- Default note is "Main" (created if missing)

### Keyboard Shortcuts

**View Screen:**
- `e` - Edit current note
- `+` - Add note (or edit if exists)
- `Escape` or `Alt + Left Arrow` - Go back to previous screen
- `Delete` - Delete current note
- `/` - Switch to All Notes (search) screen
- `Left/Right Arrow` - Navigate linked list notes (if applicable)

**List/Search Screen:**
- `+` - Add note (or edit if exists)
- `/` - Focus search bar
- `Tab` - Navigate search results
- `j/k` or `Arrow Keys` - Navigate results
- `Enter` - Open selected result

**Edit Screen:**
- `Ctrl/Cmd + P` - Toggle preview
- `Ctrl/Cmd + S` - Save and exit
- `Escape` - Exit (confirms if unsaved changes)

**Settings Screen:**
- `Ctrl/Cmd + S` - Save settings
- `Escape` - Exit (confirms if unsaved changes)

## Command-Line Interface

Noteboat includes a CLI for querying notes:

```bash
# List all notes
noteboat list

# Search for notes
noteboat search <query terms...>

# Show help
noteboat help

# Launch GUI (default)
noteboat
```

## Configuration

Config is stored in `noteboat_config.yaml` in the application documents
directory. Settings include:

- `directories`: List of note directories to search/write
- `defaultEditor`: Default editor name for new notes
- `themeMode`: Theme preference (light/dark/system)

## Design

Noteboat uses Material Design 3 with theme-aware colors for optimal readability
in both light and dark modes.

## Development

Built with Flutter/Dart. See `CLAUDE.md` for detailed architecture documentation
and development guidelines.
