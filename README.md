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

## Why jui

Large projects often accumulate dozens of useful recipes. The commands are easy to write and hard to remember.

`jui` is designed to minimize the time between thinking of a task and running it:

1. Run `jui`
2. Start typing immediately
3. Press Enter

There is no search mode to enter, no mouse required, and no editor dependency.

## Features

- Finds the nearest `justfile` by walking up from the current directory
- Uses `just --summary` as the source of truth for available recipes
- Includes recipes exposed through imports, aliases, attributes, and supported `just` syntax
- Filters recipe names and descriptions as soon as you type
- Highlights the selected row clearly
- Streams command output directly to the terminal
- Returns to the recipe list automatically after successful commands
- Keeps `jui` alive when `Ctrl-C` stops a long-running command such as a development server
- Pauses after failures so error output can be read
- Tracks recipe results for the current session:
  - `✓` succeeded
  - `✗` failed
  - `■` stopped with `Ctrl-C`
- Preserves command output while removing the `jui` interface when you quit
- Uses only the Go standard library at runtime

## Requirements

- [`just`](https://just.systems) installed and available on `PATH`
- `stty` and an ANSI-compatible terminal
- Go 1.23.2 or newer when building from source

## Install

Install the latest release with Go:

```sh
go install github.com/iOSDeveloperGuy/jui/cmd/jui@latest
```

To install the current development version from `main`:

```sh
go install github.com/iOSDeveloperGuy/jui/cmd/jui@main
```

Make sure the Go binary directory is on your `PATH`:

```sh
export PATH="$PATH:$(go env GOPATH)/bin"
```

You can also download a prebuilt binary from the GitHub Releases page.

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

Successful commands return to `jui` automatically. Failed commands wait for Enter so their output is not hidden before you can inspect it.

## Recipe descriptions

Descriptions come from comments immediately above recipes when source metadata is available:

```just
# Start the local development environment
dev:
    npm run dev

# Run the complete test suite
test:
    go test ./...
```

Recipe availability comes from `just` itself rather than from a hand-written parser, so `jui` can show the same runnable recipe set as the normal command line.

## Long-running commands

Recipes that start development servers or watchers work normally:

```just
# Start the frontend development server
dev:
    npm run dev
```

Run `dev` from `jui`, then press `Ctrl-C` when you are finished. The server stops and `jui` returns to the recipe list so another command can be launched immediately.

## Development

```sh
go test ./...
go build ./cmd/jui
```

## Release

Tags matching `v*` trigger the GitHub Actions release workflow. GoReleaser builds archives for macOS, Linux, and Windows.

## License

MIT
