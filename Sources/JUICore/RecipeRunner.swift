import Foundation
import Dispatch

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct RecipeExecution: Equatable {
    public let result: RunResult
    public let status: String
    public let shouldPause: Bool

    public init(result: RunResult, status: String, shouldPause: Bool) {
        self.result = result
        self.status = status
        self.shouldPause = shouldPause
    }
}

private final class InterruptState: @unchecked Sendable {
    private let lock = NSLock()
    private var interrupted = false

    func markInterrupted() {
        lock.lock()
        interrupted = true
        lock.unlock()
    }

    var wasInterrupted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return interrupted
    }
}

public enum RecipeRunner {
    public static func run(
        justExecutable: String,
        justfilePath: String,
        recipe: Recipe
    ) -> RecipeExecution {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: justExecutable)
        process.arguments = ["--justfile", justfilePath, recipe.name]
        process.currentDirectoryURL = URL(fileURLWithPath: justfilePath).deletingLastPathComponent()
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        let started = ContinuousClock.now
        let interruptState = InterruptState()

        // Start the child with the normal SIGINT disposition. Once it is
        // running, jui ignores SIGINT itself and forwards each interrupt to the
        // launched Process, which also targets its subtasks.
        let previousHandler = signal(SIGINT, SIG_DFL)
        var interruptSource: DispatchSourceSignal?
        defer {
            interruptSource?.setEventHandler {}
            interruptSource?.cancel()
            _ = signal(SIGINT, previousHandler)
        }

        do {
            try process.run()

            _ = signal(SIGINT, SIG_IGN)
            let source = DispatchSource.makeSignalSource(
                signal: SIGINT,
                queue: DispatchQueue.global(qos: .userInitiated)
            )
            source.setEventHandler {
                interruptState.markInterrupted()
                if process.isRunning {
                    process.interrupt()
                }
            }
            source.resume()
            interruptSource = source

            process.waitUntilExit()
        } catch {
            let duration = formatDuration(started.duration(to: .now))
            return RecipeExecution(
                result: .failed(exitCode: nil),
                status: "\(recipe.name) failed: \(error.localizedDescription) after \(duration)",
                shouldPause: true
            )
        }

        let duration = formatDuration(started.duration(to: .now))
        if interruptState.wasInterrupted
            || process.terminationReason == .uncaughtSignal
            || process.terminationStatus == 130 {
            return RecipeExecution(
                result: .stopped,
                status: "\(recipe.name) stopped after \(duration)",
                shouldPause: false
            )
        }
        if process.terminationStatus != 0 {
            return RecipeExecution(
                result: .failed(exitCode: process.terminationStatus),
                status: "\(recipe.name) failed with exit code \(process.terminationStatus) after \(duration)",
                shouldPause: true
            )
        }
        return RecipeExecution(
            result: .succeeded,
            status: "\(recipe.name) completed in \(duration)",
            shouldPause: false
        )
    }

    public static func formatDuration(_ duration: Duration) -> String {
        let components = duration.components
        let milliseconds = Double(components.seconds) * 1_000
            + Double(components.attoseconds) / 1_000_000_000_000_000

        if milliseconds < 1_000 {
            return "\(Int(milliseconds.rounded()))ms"
        }

        let seconds = milliseconds / 1_000
        var value = String(format: "%.3fs", seconds)
        while value.contains("."), value.hasSuffix("0s") {
            value.remove(at: value.index(before: value.index(before: value.endIndex)))
        }
        if value.hasSuffix(".s") {
            value.remove(at: value.index(value.endIndex, offsetBy: -2))
        }
        return value
    }
}
