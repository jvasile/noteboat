---
"@id": 4d98e5eb-2633-4d46-bb91-45aeb705771b
title: Help
mtime: 2025-10-21T15:59:01.892628
editors:
  - James Vasile
"@type":
  - note
_links:
  - CamelCase
  - NoteTitle
_tags:
  - hashtags
---

# Welcome to Noteboat!

This is your Help note. You can edit it by clicking the Edit button.

## Features

 * Links
   - Create linked notes using CamelCase words like ThisIsALink
   - Alternatively, create links with \[display text](NoteTitle), which will render as [display text](NoteTitle).
   - For non-unique titles, use query string format: Title?id=xxx (e.g., MyNote?id=abc123)

* Add tags using #hashtags
* Browse and search all your notes
* Note Types
   - Plain notes: Standard markdown notes
   - Linked List notes: Sequential notes with previous/next navigation
* Files
   * Notes are stored as markdown files with YAML frontmatter. Check the config for location of those files.
   * Edit those markdown files directly in vim or emacs or whatever text editor you favor

## Getting Started

The app starts in the All Notes (search) view. Press `/` to focus the search bar, or click the + button to create a new note. Long-press the + button to select a note type.

## Hot Keys

Keyboard shortcuts are configurable in Settings. Check your Settings to see what hotkeys do what, or to customize them to your preference.

Default shortcuts include:
 * **New Note**: `+`
 * **Search**: `/`
 * **Edit Note**: `e`
 * **Navigate Back**: `Escape` or `Alt+Left Arrow`
 * **Move Up/Down**: Arrow keys or `k`/`j`
 * **Close Dialog**: `Escape`

Fixed (non-configurable) shortcuts:
 * `Ctrl+P` - Toggle preview (Edit mode)
 * `Ctrl+S` - Save changes (Edit/Settings mode)
 * `Tab` - Navigate between UI elements
 * `Enter` - Confirm/select
 * `Delete` - Delete current note (View mode)
 * `Left/Right Arrow` - Navigate linked list notes (if applicable)
