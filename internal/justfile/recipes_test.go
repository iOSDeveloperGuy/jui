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
	if err := os.WriteFile(path, []byte(content), 0644); err != nil { t.Fatal(err) }
	recipes, err := Parse(path)
	if err != nil { t.Fatal(err) }
	if len(recipes) != 2 { t.Fatalf("expected 2 recipes, got %d", len(recipes)) }
	if recipes[0].Name != "dev" || recipes[0].Description != "Start development" { t.Fatalf("unexpected recipe: %#v", recipes[0]) }
	if recipes[1].Name != "test" || len(recipes[1].Parameters) != 1 { t.Fatalf("unexpected recipe: %#v", recipes[1]) }
}
