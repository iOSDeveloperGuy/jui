package ui

import (
	"strings"
	"testing"

	"github.com/iOSDeveloperGuy/jui/internal/justfile"
)

func TestRecipeNameColumnWidthExpandsForLongNames(t *testing.T) {
	recipes := []justfile.Recipe{
		{Name: "run"},
		{Name: "run-management-service-safari"},
	}

	got := recipeNameColumnWidth(recipes)
	want := len("run-management-service-safari")
	if got != want {
		t.Fatalf("expected width %d, got %d", want, got)
	}
}

func TestRecipeNameColumnWidthIsCapped(t *testing.T) {
	recipes := []justfile.Recipe{{Name: strings.Repeat("a", maxNameColumnWidth+20)}}

	if got := recipeNameColumnWidth(recipes); got != maxNameColumnWidth {
		t.Fatalf("expected width %d, got %d", maxNameColumnWidth, got)
	}
}

func TestTruncateTextUsesEllipsis(t *testing.T) {
	if got := truncateText("run-management-service", 10); got != "run-manag…" {
		t.Fatalf("unexpected truncation: %q", got)
	}
}
