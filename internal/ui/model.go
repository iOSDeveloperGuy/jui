package ui

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/iOSDeveloperGuy/jui/internal/justfile"
)

const selectedRowWidth = 96

type App struct {
	path     string
	recipes  []justfile.Recipe
	visible  []justfile.Recipe
	selected int
	query    string
	status   string
}

func New(path string, recipes []justfile.Recipe) *App {
	return &App{
		path:    path,
		recipes: recipes,
		visible: append([]justfile.Recipe(nil), recipes...),
		status:  "type to search  ↑/↓ select  enter run  esc clear/quit  ctrl-c quit",
	}
}

func (a *App) Run() error {
	oldState, err := rawMode()
	if err != nil {
		return fmt.Errorf("enable terminal mode: %w", err)
	}
	defer restoreMode(oldState)
	enterAlternateScreen()
	defer leaveAlternateScreen()

	in := bufio.NewReader(os.Stdin)
	for {
		a.render()
		b, err := in.ReadByte()
		if err != nil {
			return err
		}

		switch b {
		case '\r', '\n':
			if len(a.visible) > 0 {
				a.execute(a.visible[a.selected])
			}
		case 3:
			return nil
		case 27:
			quit, err := a.handleEscape(in)
			if err != nil {
				return err
			}
			if quit {
				return nil
			}
		case 127, 8:
			if len(a.query) > 0 {
				a.query = a.query[:len(a.query)-1]
				a.filter()
			}
		default:
			if b >= 32 && b <= 126 {
				a.query += string(b)
				a.filter()
			}
		}
	}
}

func (a *App) handleEscape(in *bufio.Reader) (bool, error) {
	if in.Buffered() == 0 {
		if a.query == "" {
			return true, nil
		}
		a.clearQuery()
		return false, nil
	}

	second, err := in.ReadByte()
	if err != nil {
		if a.query == "" {
			return true, nil
		}
		a.clearQuery()
		return false, nil
	}
	if second != '[' {
		if a.query == "" {
			return true, nil
		}
		a.clearQuery()
		return false, nil
	}

	third, err := in.ReadByte()
	if err != nil {
		return false, err
	}
	switch third {
	case 'A':
		if a.selected > 0 {
			a.selected--
		}
	case 'B':
		if a.selected+1 < len(a.visible) {
			a.selected++
		}
	}
	return false, nil
}

func (a *App) clearQuery() {
	if a.query == "" {
		return
	}
	a.query = ""
	a.filter()
}

func (a *App) filter() {
	q := strings.ToLower(strings.TrimSpace(a.query))
	a.visible = a.visible[:0]
	for _, r := range a.recipes {
		haystack := strings.ToLower(r.Name + " " + r.Description)
		if fuzzyContains(haystack, q) {
			a.visible = append(a.visible, r)
		}
	}
	a.selected = 0
}

func fuzzyContains(value, query string) bool {
	if query == "" {
		return true
	}
	i := 0
	for _, r := range value {
		if i < len(query) && byte(r) == query[i] {
			i++
		}
	}
	return i == len(query)
}

func (a *App) execute(recipe justfile.Recipe) {
	restoreForCommand()
	leaveAlternateScreen()
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
	enterAlternateScreen()
}

func (a *App) render() {
	fmt.Print("\x1b[2J\x1b[H")
	fmt.Printf("\x1b[1;36mjui\x1b[0m  \x1b[2m%s\x1b[0m\n", a.path)

	if a.query == "" {
		fmt.Print("\x1b[2mSearch: type to filter recipes\x1b[0m\n\n")
	} else {
		fmt.Printf("\x1b[1mSearch: %s_\x1b[0m\n\n", a.query)
	}

	if len(a.visible) == 0 {
		fmt.Println("  No matching recipes")
	}
	for i, r := range a.visible {
		desc := r.Description
		if desc == "" {
			desc = "No description"
		}
		row := fmt.Sprintf("  %-24s %s", r.Name, desc)
		if len(row) > selectedRowWidth {
			row = row[:selectedRowWidth]
		}
		if i == a.selected {
			fmt.Printf("\x1b[1;7m %-*s \x1b[0m\n", selectedRowWidth, strings.TrimSpace(row))
		} else {
			fmt.Printf("%-*s\n", selectedRowWidth+2, row)
		}
	}
	fmt.Printf("\n\x1b[2m%s\x1b[0m", a.status)
}

func rawMode() (string, error) {
	cmd := exec.Command("stty", "-g")
	cmd.Stdin = os.Stdin
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	state := strings.TrimSpace(string(out))
	cmd = exec.Command("stty", "-icanon", "-echo", "min", "1", "time", "0")
	cmd.Stdin = os.Stdin
	return state, cmd.Run()
}

func restoreMode(state string) {
	if state == "" {
		return
	}
	cmd := exec.Command("stty", state)
	cmd.Stdin = os.Stdin
	_ = cmd.Run()
}

func enterAlternateScreen() {
	fmt.Print("\x1b[?1049h\x1b[?25l\x1b[2J\x1b[H")
}

func leaveAlternateScreen() {
	fmt.Print("\x1b[?25h\x1b[?1049l")
}

func restoreForCommand() {
	cmd := exec.Command("stty", "sane")
	cmd.Stdin = os.Stdin
	_ = cmd.Run()
	fmt.Print("\x1b[?25h")
}
