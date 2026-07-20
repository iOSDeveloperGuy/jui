import Foundation
import Dispatch
import XCTest
@testable import JUICore

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

final class RecipeRunnerTests: XCTestCase {
    func testCtrlCIsForwardedToRunningRecipe() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let justfile = directory.appendingPathComponent("justfile")
        try "dev:\n\techo dev\n".write(to: justfile, atomically: true, encoding: .utf8)

        let fakeJust = directory.appendingPathComponent("just")
        try """
        #!/bin/sh
        trap 'exit 130' INT
        sleep 5 &
        wait $!
        """.write(to: fakeJust, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fakeJust.path)

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            _ = kill(getpid(), SIGINT)
        }

        let started = Date()
        let execution = RecipeRunner.run(
            justExecutable: fakeJust.path,
            justfilePath: justfile.path,
            recipe: Recipe(name: "dev")
        )
        let elapsed = Date().timeIntervalSince(started)

        XCTAssertEqual(execution.result, .stopped)
        XCTAssertLessThan(elapsed, 3, "Ctrl-C was not forwarded promptly to the recipe process")
    }
}
