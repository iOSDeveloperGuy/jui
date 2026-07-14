package ui

import (
	"strings"
	"testing"

	"github.com/iOSDeveloperGuy/jui/internal/justfile"
)

func TestRecipeViewportCapacityReservesHeaderAndFooter(t *testing.T) {
	if got := recipeViewportCapacity(24); got != 19 {
		t.Fatalf("expected 19 visible recipes, got %d", got)
	}
	if got := recipeViewportCapacity(3); got != 1 {
		t.Fatalf("expected a minimum capacity of 1, got %d", got)
	}
}

func TestViewportRangeKeepsSelectionVisible(t *testing.T) {
	tests := []struct {
		name               string
		total              int
		selected           int
		offset             int
		capacity           int
		wantStart, wantEnd int
	}{
		{name: "first page", total: 50, selected: 0, offset: 0, capacity: 10, wantStart: 0, wantEnd: 10},
		{name: "scroll down one row", total: 50, selected: 10, offset: 0, capacity: 10, wantStart: 1, wantEnd: 11},
		{name: "selection below viewport", total: 50, selected: 25, offset: 1, capacity: 10, wantStart: 16, wantEnd: 26},
		{name: "selection above viewport", total: 50, selected: 5, offset: 16, capacity: 10, wantStart: 5, wantEnd: 15},
		{name: "last page", total: 50, selected: 49, offset: 16, capacity: 10, wantStart: 40, wantEnd: 50},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			start, end := viewportRange(test.total, test.selected, test.offset, test.capacity)
			if start != test.wantStart || end != test.wantEnd {
				t.Fatalf("expected %d-%d, got %d-%d", test.wantStart, test.wantEnd, start, end)
			}
		})
	}
}

func TestRowWidthLeavesFinalTerminalColumnUnused(t *testing.T) {
	if got := rowWidthForTerminal(80); got != 79 {
		t.Fatalf("expected width 79, got %d", got)
	}
	if got := rowWidthForTerminal(160); got != selectedRowWidth {
		t.Fatalf("expected capped width %d, got %d", selectedRowWidth, got)
	}
}

func TestNameColumnShrinksToPreserveDescriptionSpace(t *testing.T) {
	recipes := []justfile.Recipe{{Name: strings.Repeat("a", maxNameColumnWidth)}}
	if got := fitNameColumnWidth(recipes, 40); got != 23 {
		t.Fatalf("expected name width 23, got %d", got)
	}
}

func TestPadTextUsesDisplayRunes(t *testing.T) {
	if got := padText("✓", 3); got != "✓  " {
		t.Fatalf("unexpected padded text: %q", got)
	}
}
