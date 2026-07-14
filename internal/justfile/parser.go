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
	Name        string
	Description string
	Parameters  []string
	SourceLine  int
}

var (
	// Source parsing is only used to enrich recipes with descriptions and
	// parameters. `just --summary` is the source of truth for recipe names.
	recipePattern = regexp.MustCompile(`^@?([A-Za-z_][A-Za-z0-9_-]*)(?:\s+([^:]+))?:\s*(?:#.*)?$`)
	aliasPattern  = regexp.MustCompile(`^alias\s+([A-Za-z_][A-Za-z0-9_-]*)\s*:=\s*[A-Za-z_][A-Za-z0-9_-]*\s*(?:#.*)?$`)
)

func Discover(start string) (string, error) {
	dir, err := filepath.Abs(start)
	if err != nil {
		return "", err
	}
	info, err := os.Stat(dir)
	if err == nil && !info.IsDir() {
		dir = filepath.Dir(dir)
	}
	for {
		for _, name := range []string{"justfile", "Justfile", ".justfile"} {
			candidate := filepath.Join(dir, name)
			if st, err := os.Stat(candidate); err == nil && !st.IsDir() {
				return candidate, nil
			}
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return "", errors.New("no justfile found in this directory or any parent")
}

func Parse(path string) ([]Recipe, error) {
	metadata, sourceErr := parseSource(path)
	names, listErr := listAvailableRecipes(path)

	// `just` understands imports, modules, attributes, aliases, and future
	// syntax changes better than a hand-written parser can. When available,
	// always use its output as the authoritative recipe set.
	if listErr == nil {
		byName := make(map[string]Recipe, len(metadata))
		for _, recipe := range metadata {
			byName[recipe.Name] = recipe
		}

		recipes := make([]Recipe, 0, len(names))
		for _, name := range names {
			recipe, ok := byName[name]
			if !ok {
				recipe = Recipe{Name: name}
			}
			recipes = append(recipes, recipe)
		}
		if len(recipes) == 0 {
			return nil, fmt.Errorf("no recipes found in %s", path)
		}
		return recipes, nil
	}

	// Keep source parsing as a compatibility fallback for tests, unusual
	// environments, or older `just` installations without --summary.
	if sourceErr != nil {
		return nil, sourceErr
	}
	if len(metadata) == 0 {
		return nil, fmt.Errorf("list recipes with just: %w", listErr)
	}
	sort.SliceStable(metadata, func(i, j int) bool { return metadata[i].Name < metadata[j].Name })
	return metadata, nil
}

func listAvailableRecipes(path string) ([]string, error) {
	cmd := exec.Command("just", "--justfile", path, "--summary", "--unsorted")
	cmd.Dir = filepath.Dir(path)
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}
	return strings.Fields(string(output)), nil
}

func parseSource(path string) ([]Recipe, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var recipes []Recipe
	var comments []string
	scanner := bufio.NewScanner(file)
	lineNo := 0
	for scanner.Scan() {
		lineNo++
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)

		if strings.HasPrefix(trimmed, "#") {
			comments = append(comments, strings.TrimSpace(strings.TrimPrefix(trimmed, "#")))
			continue
		}
		if trimmed == "" {
			comments = nil
			continue
		}
		if strings.HasPrefix(line, " ") || strings.HasPrefix(line, "\t") {
			continue
		}

		// Attributes belong to the declaration on the next line, so keep any
		// preceding description comments intact.
		if strings.HasPrefix(trimmed, "[") && strings.HasSuffix(trimmed, "]") {
			continue
		}

		if match := aliasPattern.FindStringSubmatch(line); match != nil {
			recipes = append(recipes, Recipe{
				Name:        match[1],
				Description: strings.TrimSpace(strings.Join(comments, " ")),
				SourceLine:  lineNo,
			})
			comments = nil
			continue
		}

		match := recipePattern.FindStringSubmatch(line)
		if match == nil {
			comments = nil
			continue
		}
		recipes = append(recipes, Recipe{
			Name:        match[1],
			Description: strings.TrimSpace(strings.Join(comments, " ")),
			Parameters:  strings.Fields(strings.TrimSpace(match[2])),
			SourceLine:  lineNo,
		})
		comments = nil
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return recipes, nil
}

func Run(path, recipe string, args []string) *exec.Cmd {
	commandArgs := []string{"--justfile", path, recipe}
	commandArgs = append(commandArgs, args...)
	cmd := exec.Command("just", commandArgs...)
	cmd.Dir = filepath.Dir(path)
	return cmd
}
