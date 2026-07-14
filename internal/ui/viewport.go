package ui

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/iOSDeveloperGuy/jui/internal/justfile"
)

const (
	defaultTerminalRows     = 24
	defaultTerminalColumns  = selectedRowWidth + 1
	reservedScreenRows      = 5
	minimumDescriptionWidth = 12
	minimumCompactNameWidth = 8
)

func terminalDimensions() (rows, columns int) {
	rows, columns = defaultTerminalRows, defaultTerminalColumns

	cmd := exec.Command("stty", "size")
	cmd.Stdin = os.Stdin
	output, err := cmd.Output()
	if err != nil {
		return rows, columns
	}

	var measuredRows, measuredColumns int
	if _, err := fmt.Sscan(string(output), &measuredRows, &measuredColumns); err != nil {
		return rows, columns
	}
	if measuredRows > 0 {
		rows = measuredRows
	}
	if measuredColumns > 0 {
		columns = measuredColumns
	}
	return rows, columns
}

func rowWidthForTerminal(columns int) int {
	if columns <= 1 {
		return 1
	}

	// Leave the final terminal column unused. Writing into it can cause some
	// terminals to wrap before the explicit newline is printed.
	width := columns - 1
	if width > selectedRowWidth {
		return selectedRowWidth
	}
	return width
}

func recipeViewportCapacity(rows int) int {
	capacity := rows - reservedScreenRows
	if capacity < 1 {
		return 1
	}
	return capacity
}

func viewportRange(total, selected, offset, capacity int) (start, end int) {
	if total <= 0 {
		return 0, 0
	}
	if capacity < 1 {
		capacity = 1
	}
	if selected < 0 {
		selected = 0
	}
	if selected >= total {
		selected = total - 1
	}

	maxStart := total - capacity
	if maxStart < 0 {
		maxStart = 0
	}
	if offset < 0 {
		offset = 0
	}
	if offset > maxStart {
		offset = maxStart
	}

	if selected < offset {
		offset = selected
	} else if selected >= offset+capacity {
		offset = selected - capacity + 1
	}
	if offset > maxStart {
		offset = maxStart
	}

	end = offset + capacity
	if end > total {
		end = total
	}
	return offset, end
}

func fitNameColumnWidth(recipes []justfile.Recipe, rowWidth int) int {
	width := recipeNameColumnWidth(recipes)
	maximum := rowWidth - rowPrefixWidth - rowGapWidth - minimumDescriptionWidth
	if maximum < minimumCompactNameWidth {
		maximum = rowWidth - rowPrefixWidth - rowGapWidth
	}
	if maximum < 1 {
		maximum = 1
	}
	if width > maximum {
		width = maximum
	}
	return width
}
