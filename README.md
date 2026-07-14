# jui

A focused terminal interface for discovering and running [`just`](https://just.systems) recipes.

`jui` finds the nearest `justfile`, lists documented recipes, supports keyboard search and selection, prompts for recipe arguments, and runs the chosen command without forcing you to memorize every recipe name.

## Features

- Finds the nearest `justfile` by walking up from the current directory
- Lists recipes and descriptions from comments
- Filters recipes as you type
- Supports arrow keys, `j`/`k`, Enter, Escape, and `q`
- Prompts for required positional arguments
- Streams the selected recipe's output
- Reports exit status and execution duration
- Uses only the Go standard library at runtime

## Requirements

- Go 1.24 or newer to build from source
- [`just`](https://just.systems) installed and available on `PATH`
- An ANSI-compatible terminal

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

Start with a search already entered:

```sh
jui test
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
| Type | Filter recipes |
| Up / `Ctrl-P` | Previous recipe |
| Down / `Ctrl-N` | Next recipe |
| Enter | Run selected recipe |
| Backspace | Remove search character |
| Escape | Clear search |
| `Ctrl-C` | Quit |

When the search field is empty, `j` and `k` also move through the list and `q` quits.

## Development

```sh
go test ./...
go build ./cmd/jui
```

## Release

Tags matching `v*` trigger the GitHub Actions release workflow and GoReleaser builds archives for macOS, Linux, and Windows.

## License

MIT
