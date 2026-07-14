package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"runtime/debug"
	"strings"

	"github.com/iOSDeveloperGuy/jui/internal/justfile"
	"github.com/iOSDeveloperGuy/jui/internal/ui"
)

var version = "dev"

func main() {
	showVersion := flag.Bool("version", false, "print version")
	flag.Parse()
	if *showVersion {
		fmt.Println("jui", buildVersion())
		return
	}
	if _, err := exec.LookPath("just"); err != nil {
		fatal("just is not installed or not on PATH")
	}
	if _, err := exec.LookPath("stty"); err != nil {
		fatal("stty is required")
	}
	path, err := justfile.Discover(".")
	if err != nil {
		fatal(err.Error())
	}
	recipes, err := justfile.Parse(path)
	if err != nil {
		fatal(err.Error())
	}
	if err := ui.New(path, recipes).Run(); err != nil {
		fatal(err.Error())
	}
}

func buildVersion() string {
	if version != "" && version != "dev" {
		return version
	}

	info, ok := debug.ReadBuildInfo()
	if !ok || info.Main.Version == "" || info.Main.Version == "(devel)" {
		return "dev"
	}

	return strings.TrimPrefix(info.Main.Version, "v")
}

func fatal(message string) {
	fmt.Fprintln(os.Stderr, "jui:", message)
	os.Exit(1)
}
