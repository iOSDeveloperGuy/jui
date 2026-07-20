import Foundation

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

private func handleInterruptWithoutExiting(_ signalNumber: Int32) {}

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

        // Ensure the child starts with normal SIGINT behavior. Installing jui's
        // handler before Process.run() can cause the spawned process tree to
        // inherit an ignored interrupt on some platforms.
        let previousHandler = signal(SIGINT, SIG_DFL)
        defer { _ = signal(SIGINT, previousHandler) }

        do {
            try process.run()
            _ = signal(SIGINT, handleInterruptWithoutExiting)
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
        if process.terminationReason == .uncaughtSignal || process.terminationStatus == 130 {
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
