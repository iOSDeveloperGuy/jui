# jui

A focused terminal interface for discovering and running [`just`](https://just.systems) recipes.

`jui` finds the nearest `justfile`, lists documented recipes, supports fuzzy search and keyboard selection, and runs the chosen recipe without forcing you to memorize every command.

## Features

- Finds the nearest `justfile` by walking up from the current directory
- Lists recipes and descriptions from comments
- Fuzzy-filters recipe names and descriptions
- Supports arrow-key navigation
- Streams the selected recipe's output
- Reports exit status and execution duration
- Uses only the Go standard library at runtime

## Requirements

- Go 1.23.2 or newer to build from source
- [`just`](https://just.systems) installed and available on `PATH`
- `stty` and an ANSI-compatible terminal

## Install

Download a binary from the GitHub Releases page, or build it locally:

```sh
go install github.com/iOSDeveloperGuy/jui/cmd/jui@latest
```

## Usage

From a directory containing a `justfile`, or any child directory:

```sh
jui
```

Check the installed version:

```sh
jui --version
```

## Justfile descriptions

Descriptions come from comments immediately above a recipe:

```just
# Start the local development environment
dev:
    docker compose up

# Run the complete test suite
test:
    go test ./...
```

## Controls

| Key | Action |
| --- | --- |
| `/` | Open search |
| Up | Previous recipe |
| Down | Next recipe |
| Enter | Run selected recipe |
| Escape | Cancel and clear search |
| `q` | Quit when not searching |
| `Ctrl-C` | Quit |

## Development

```sh
go test ./...
go build ./cmd/jui
```

## Release

Tags matching `v*` trigger the GitHub Actions release workflow and GoReleaser builds archives for macOS, Linux, and Windows.

## License

MIT
