# jui

**Find and run the right `just` recipe as fast as possible.**

`jui` is a keyboard-first terminal launcher for [`just`](https://just.systems). Open it, start typing, press Enter, and get back to work without memorizing recipe names or scrolling through a long `just --list` output.

```text
jui  /path/to/project/justfile
Search: dev_

  ✓ build                    Build the application
    dev                      Start the development server
    dev-clean                Reset and start development
    test                     Run the test suite
```

## Features

- Finds the nearest `justfile` by walking up from the current directory
- Uses `just --summary` as the source of truth for available recipes
- Includes recipes exposed through imports, aliases, attributes, and supported `just` syntax
- Filters recipe names and descriptions as soon as you type
- Keeps the selected recipe visible in small terminals
- Streams command output directly to the terminal
- Returns to the recipe list automatically after successful commands
- Keeps `jui` alive when `Ctrl-C` stops a long-running command
- Pauses after failures so error output can be read
- Tracks recipe results for the current session:
  - `✓` succeeded
  - `✗` failed
  - `■` stopped with `Ctrl-C`
- Preserves command output while removing the `jui` interface when you quit
- Uses no third-party runtime dependencies

## Requirements

- [`just`](https://just.systems) installed and available on `PATH`
- An ANSI-compatible POSIX terminal
- macOS or Linux
- Swift 6.0 or newer when building from source

## Build and install

```sh
swift test
swift build -c release
install .build/release/jui ~/.local/bin/jui
```

Make sure `~/.local/bin` is on your `PATH`. Release archives can also be downloaded from GitHub Releases.

## Usage

Run `jui` from a directory containing a `justfile`, or from any child directory:

```sh
jui
```

Then type part of a recipe name or description and press Enter.

Check the installed version:

```sh
jui --version
```

## Controls

| Key | Action |
| --- | --- |
| Type | Filter recipes immediately |
| Backspace | Remove the last search character |
| Up | Select the previous recipe |
| Down | Select the next recipe |
| Enter | Run the selected recipe |
| Escape | Clear an active search |
| Escape | Quit when the search is empty |
| `Ctrl-C` | Quit while viewing the recipe list |
| `Ctrl-C` | Stop a running recipe and return to `jui` |

Successful commands return to `jui` automatically. Failed commands wait for Enter so their output remains visible.

## Recipe descriptions

Descriptions come from comments immediately above recipes when source metadata is available:

```just
# Start the local development environment
dev:
    npm run dev

# Run the complete test suite
test:
    swift test
```

Recipe availability comes from `just` itself rather than from a hand-written parser, so `jui` shows the same runnable recipe set as the normal command line.

## Development

```sh
swift test
swift build
```

The package separates the terminal-independent state, parsing, and layout code into `JUICore`, with the executable entry point in `JUI`.

## Release

Tags matching `v*` trigger the GitHub Actions release workflow. It builds archives for the current GitHub-hosted macOS and Linux architectures; Linux builds statically link the Swift standard library.

## License

MIT
