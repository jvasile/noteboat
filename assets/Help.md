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

### Global
 * `/` - Focus search bar / switch to All Notes view
 * `+` - Create new note (shows type selector)
 * `Escape` - Close dialogs, cancel edits, go back

### Viewing Notes
 * `e` - Edit current note
 * `Delete` - Delete current note (with confirmation)
 * `Escape` or `Alt+Left` - Go back to previous screen

### Editing Notes
 * `Ctrl+P` - Toggle preview
 * `Ctrl+S` - Save changes
 * `Escape` - Close editor (prompts if unsaved changes)

### Linked List Notes
 * `Left Arrow` - Go to previous note
 * `Right Arrow` - Go to next note

### Dialogs
 * `Arrow Keys` - Navigate between options
 * `Enter` - Confirm/select highlighted option
 * `Escape` - Cancel
