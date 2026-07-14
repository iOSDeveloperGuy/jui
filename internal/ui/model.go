package ui

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/iOSDeveloperGuy/jui/internal/justfile"
)

type App struct {
	path string
	recipes []justfile.Recipe
	visible []justfile.Recipe
	selected int
	query string
	status string
}

func New(path string, recipes []justfile.Recipe) *App {
	return &App{path: path, recipes: recipes, visible: append([]justfile.Recipe(nil), recipes...), status: "↑/↓ select  / search  enter run  q quit"}
}

func (a *App) Run() error {
	oldState, err := rawMode()
	if err != nil { return fmt.Errorf("enable terminal mode: %w", err) }
	defer restoreMode(oldState)
	defer fmt.Print("\x1b[?25h\x1b[2J\x1b[H")
	fmt.Print("\x1b[?25l")
	in := bufio.NewReader(os.Stdin)
	for {
		a.render()
		b, err := in.ReadByte()
		if err != nil { return err }
		switch b {
		case 'q':
			if a.query == "" { return nil }
			a.query += "q"; a.filter()
		case '/':
			if err := a.search(in); err != nil { return err }
		case '\r', '\n':
			if len(a.visible) > 0 { a.execute(a.visible[a.selected]) }
		case 3:
			return nil
		case 27:
			if err := a.handleEscape(in); err != nil && err != io.EOF { return err }
		}
	}
}

func (a *App) handleEscape(in *bufio.Reader) error {
	second, err := in.ReadByte(); if err != nil { return err }
	if second != '[' { return nil }
	third, err := in.ReadByte(); if err != nil { return err }
	switch third {
	case 'A': if a.selected > 0 { a.selected-- }
	case 'B': if a.selected+1 < len(a.visible) { a.selected++ }
	}
	return nil
}

func (a *App) search(in *bufio.Reader) error {
	a.query = ""
	for {
		a.renderSearch()
		b, err := in.ReadByte(); if err != nil { return err }
		switch b {
		case '\r', '\n': a.filter(); return nil
		case 27: a.query = ""; a.filter(); return nil
		case 127, 8: if len(a.query) > 0 { a.query = a.query[:len(a.query)-1] }
		default: if b >= 32 && b <= 126 { a.query += string(b) }
		}
		a.filter()
	}
}

func (a *App) filter() {
	q := strings.ToLower(strings.TrimSpace(a.query))
	a.visible = a.visible[:0]
	for _, r := range a.recipes {
		haystack := strings.ToLower(r.Name + " " + r.Description)
		if fuzzyContains(haystack, q) { a.visible = append(a.visible, r) }
	}
	if a.selected >= len(a.visible) { a.selected = max(0, len(a.visible)-1) }
}

func fuzzyContains(value, query string) bool {
	if query == "" { return true }
	i := 0
	for _, r := range value {
		if i < len(query) && byte(r) == query[i] { i++ }
	}
	return i == len(query)
}

func (a *App) execute(recipe justfile.Recipe) {
	restoreForCommand()
	fmt.Print("\x1b[2J\x1b[H")
	fmt.Printf("Running \x1b[1mjust %s\x1b[0m\n\n", recipe.Name)
	start := time.Now()
	cmd := justfile.Run(a.path, recipe.Name, nil)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	err := cmd.Run()
	duration := time.Since(start).Round(time.Millisecond)
	if exitErr, ok := err.(*exec.ExitError); ok {
		a.status = fmt.Sprintf("%s failed with exit code %d after %s", recipe.Name, exitErr.ExitCode(), duration)
	} else if err != nil {
		a.status = fmt.Sprintf("%s failed: %v", recipe.Name, err)
	} else {
		a.status = fmt.Sprintf("%s completed in %s", recipe.Name, duration)
	}
	fmt.Printf("\n%s\nPress Enter to return to jui...", a.status)
	_, _ = bufio.NewReader(os.Stdin).ReadString('\n')
	_, _ = rawMode()
	fmt.Print("\x1b[?25l")
}

func (a *App) render() {
	fmt.Print("\x1b[2J\x1b[H")
	fmt.Printf("\x1b[1;36mjui\x1b[0m  \x1b[2m%s\x1b[0m\n", a.path)
	fmt.Printf("\x1b[2mSearch: %s\x1b[0m\n\n", a.query)
	if len(a.visible) == 0 { fmt.Println("  No matching recipes") }
	for i, r := range a.visible {
		prefix := "  "
		if i == a.selected { prefix = "\x1b[1;32m› \x1b[0m" }
		desc := r.Description
		if desc == "" { desc = "No description" }
		fmt.Printf("%s\x1b[1m%-24s\x1b[0m %s\n", prefix, r.Name, desc)
	}
	fmt.Printf("\n\x1b[2m%s\x1b[0m", a.status)
}

func (a *App) renderSearch() { a.render(); fmt.Printf("\n\x1b[1mSearch: %s_\x1b[0m", a.query) }

func rawMode() (string, error) {
	cmd := exec.Command("stty", "-g"); cmd.Stdin = os.Stdin
	out, err := cmd.Output(); if err != nil { return "", err }
	state := strings.TrimSpace(string(out))
	cmd = exec.Command("stty", "-icanon", "-echo", "min", "1", "time", "0"); cmd.Stdin = os.Stdin
	return state, cmd.Run()
}

func restoreMode(state string) {
	if state == "" { return }
	cmd := exec.Command("stty", state); cmd.Stdin = os.Stdin; _ = cmd.Run()
}

func restoreForCommand() {
	cmd := exec.Command("stty", "sane"); cmd.Stdin = os.Stdin; _ = cmd.Run(); fmt.Print("\x1b[?25h")
}

func max(a, b int) int { if a > b { return a }; return b }
