package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"runtime/debug"

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
