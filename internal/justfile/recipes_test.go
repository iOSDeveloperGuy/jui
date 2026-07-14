package justfile

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseRecipes(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "justfile")
	content := "# Start development\ndev:\n\techo dev\n\n# Run tests\ntest package='...':\n\tgo test {{package}}\n"
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}
	recipes, err := Parse(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(recipes) != 2 {
		t.Fatalf("expected 2 recipes, got %d", len(recipes))
	}
	if recipes[0].Name != "dev" || recipes[0].Description != "Start development" {
		t.Fatalf("unexpected recipe: %#v", recipes[0])
	}
	if recipes[1].Name != "test" || len(recipes[1].Parameters) != 1 {
		t.Fatalf("unexpected recipe: %#v", recipes[1])
	}
}

func TestParseQuietRecipeAliasAndAttributes(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "justfile")
	content := `# Run the application
[group('development')]
@run:
	echo run

# Short name for run
alias r := run
`
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}

	recipes, err := Parse(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(recipes) != 2 {
		t.Fatalf("expected 2 recipes, got %d: %#v", len(recipes), recipes)
	}
	if recipes[0].Name != "r" || recipes[0].Description != "Short name for run" {
		t.Fatalf("unexpected alias: %#v", recipes[0])
	}
	if recipes[1].Name != "run" || recipes[1].Description != "Run the application" {
		t.Fatalf("unexpected quiet recipe: %#v", recipes[1])
	}
}
