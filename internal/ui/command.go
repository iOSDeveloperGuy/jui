package ui

import (
	"context"
	"os"
	"os/exec"
	"os/signal"
)

// runCommand keeps jui alive when the terminal sends Ctrl-C to the foreground
// process group. The recipe and its subprocesses still receive the interrupt,
// while the parent records it and returns to the launcher afterward.
func runCommand(cmd *exec.Cmd) (err error, interrupted bool) {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	err = cmd.Run()
	return err, ctx.Err() != nil
}
