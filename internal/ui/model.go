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
		path:     path,
		re