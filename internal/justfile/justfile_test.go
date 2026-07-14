package justfile

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestParseSourceRecipes(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "justfile")
	content := "# Start development\ndev:\n\techo dev\n\n# Run quietly\n@run:\n\techo run\n\nalias r := run\n"
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}

	recipes, err := parseSource(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(recipes) != 3 {
		t.Fatalf("expected 3 recipes, got %d", len(recipes))
	}
	if recipes[0].Name != "dev" || recipes[0].Description != "Start development" {
		t.Fatalf("unexpected recipe: %#v", recipes[0])
	}
	if recipes[1].Name != "run" || recipes[1].Description != "Run quietly" {
		t.Fatalf("unexpected quiet recipe: %#v", recipes[1])
	}
	if recipes[2].Name != "r" {
		t.Fatalf("unexpected alias: %#v", recipes[2])
	}
}

func TestParseUsesJustSummaryAsSourceOfTruth(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("test helper uses a shell script")
	}

	dir := t.TempDir()
	path := filepath.Join(dir, "justfile")
	if err := os.WriteFile(path, []byte("# Local recipe\nlocal:\n\techo local\n"), 0644); err != nil {
		t.Fatal(err)
	}

	binDir := filepath.Join(dir, "bin")
	if err := os.Mkdir(binDir, 0755); err != nil {
		t.Fatal(err)
	}
	fakeJust := filepath.Join(binDir, "just")
	if err := os.WriteFile(fakeJust, []byte("#!/bin/sh\nprintf 'local imported-run alias-run\\n'\n"), 0755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", binDir+string(os.PathListSeparator)+os.Getenv("PATH"))

	recipes, err := Parse(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(recipes) != 3 {
		t.Fatalf("expected 3 authoritative recipes, got %d: %#v", len(recipes), recipes)
	}
	if recipes[0].Name != "local" || recipes[0].Description != "Local recipe" {
		t.Fatalf("expected source metadata to enrich local recipe: %#v", recipes[0])
	}
	if recipes[1].Name != "imported-run" || recipes[2].Name != "alias-run" {
		t.Fatalf("missing recipes returned by just summary: %#v", recipes)
	}
}
