package justfile

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type Recipe struct {
	Name string
	Description string
	Parameters []string
	SourceLine int
}

var recipePattern = regexp.MustCompile(`^([A-Za-z_][A-Za-z0-9_-]*)(?:\s+([^:]+))?:\s*(?:#.*)?$`)

func Discover(start string) (string, error) {
	dir, err := filepath.Abs(start)
	if err != nil { return "", err }
	info, err := os.Stat(dir)
	if err == nil && !info.IsDir() { dir = filepath.Dir(dir) }
	for {
		for _, name := range []string{"justfile", "Justfile", ".justfile"} {
			candidate := filepath.Join(dir, name)
			if st, err := os.Stat(candidate); err == nil && !st.IsDir() { return candidate, nil }
		}
		parent := filepath.Dir(dir)
		if parent == dir { break }
		dir = parent
	}
	return "", errors.New("no justfile found in this directory or any parent")
}

func Parse(path string) ([]Recipe, error) {
	f, err := os.Open(path)
	if err != nil { return nil, err }
	defer f.Close()
	var recipes []Recipe
	var comments []string
	scanner := bufio.NewScanner(f)
	lineNo := 0
	for scanner.Scan() {
		lineNo++
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "#") {
			comments = append(comments, strings.TrimSpace(strings.TrimPrefix(trimmed, "#")))
			continue
		}
		if trimmed == "" { comments = nil; continue }
		if strings.HasPrefix(line, " ") || strings.HasPrefix(line, "\t") { continue }
		match := recipePattern.FindStringSubmatch(line)
		if match == nil { comments = nil; continue }
		params := strings.Fields(strings.TrimSpace(match[2]))
		recipes = append(recipes, Recipe{Name: match[1], Description: strings.TrimSpace(strings.Join(comments, " ")), Parameters: params, SourceLine: lineNo})
		comments = nil
	}
	if err := scanner.Err(); err != nil { return nil, err }
	sort.SliceStable(recipes, func(i, j int) bool { return recipes[i].Name < recipes[j].Name })
	if len(recipes) == 0 { return nil, fmt.Errorf("no recipes found in %s", path) }
	return recipes, nil
}

func Run(path, recipe string, args []string) *exec.Cmd {
	commandArgs := []string{"--justfile", path, recipe}
	commandArgs = append(commandArgs, args...)
	cmd := exec.Command("just", commandArgs...)
	cmd.Dir = filepath.Dir(path)
	return cmd
}
