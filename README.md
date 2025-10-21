# Note Boat

Note boat is a collection of linked notes and other data objects.  It is an app
that allows creation, editing, browsing, and searching of notes.

Object types fit into a hierarchical type tree.  That is, there is a base data
object called a note that contains some basic data: title, text, tags, mtime,
links. Titles should be one word, camelcased.  They match without regard to
case.  Each note must have a unique title.  All the other data types inherit
from this base note.

Another type of data is the graphic.  This type adds a filename to the data
struct.  That filename is the location of the graphic file.

Another type of data might be a receipt.  This is just a picture of a receipt.
There might be some additional data fields for amount, client, purpose, etc.

## Architecture

Noteboat's backend is just a bunch of files.  Notes are just text files in some
sensible format that allows for data fields and a text block.  Markdown works
well.  Noteboat supports yaml and json.   The text field supports markdown.

Noteboat's front end might turn the structured data document into html or some
other representation.  But the backend documents are the canonical information.

Noteboat files might be in a variety of directories.  Noteboat might search many
directories for notes, but that isn't semantically relevant to resolving links
or tags or anything like that.  Directories aren't namespaces.  Filenames are
always resolved relative to the directory of the note containing the filename.
Links are just titles of other notes.

## Interface

In addition to the various GUI entrypoints in different operating systems, there
is a CLI that can be used to query the notes in Noteboat.

When viewing a note, users can click on tags and links to access other notes.

## Config

Noteboat stores its config in a yaml file in standard places used for storage of
user application config on each OS.

# Design

Noteboat uses material design.
