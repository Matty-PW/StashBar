# StashBar

A macOS menu bar utility for stashing things you may need soon, whether that be a small note or a file on its way from one app to another.

> **Status:** early development.

## Why

Moving a file from Finder into an email, or holding a snippet of text between two apps, usually means a detour through Desktop or a TextEdit window. StashBar keeps a notepad and a temporary file shelf one click away in the menu bar, so the detour disappears.

## Features

- **Quick note** -  small notepad in the menu bar popover
- **File shelf** - drag files in from Finder to hold them temporarily, drag them back out into any app
- **Export notes as .md** - export as Markdown to a local folder (Obsidian compatible)
- **Export to Apple Notes** - export directly to Apple Notes
- **Global customisable hotkey** - to summon the popover from anywhere
- **Spring loaded opening** - opens automatically when holding a file over the icon
- **Start on login** - option to start automatically when you login
- **Settings Menu** - separate settings menu to choose preferences

## Requirements

- macOS 14 or later
- Xcode 15 or later to build

## Building

```bash
git clone https://github.com/Matty-PW/StashBar.git
cd StashBar
open StashBar.xcodeproj
```

Then build and run in Xcode (`Cmd+R`). StashBar runs as a menu bar agent — it has no Dock icon and no main window, so look for the tray icon in the menu bar after launching.

## License

MIT — see [LICENSE](LICENSE).
