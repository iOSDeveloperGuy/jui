import Foundation
import XCTest
@testable import JUICore

final class JustfileServiceTests: XCTestCase {
    func testDiscoverWalksUpToNearestJustfile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nested = root.appendingPathComponent("a/b/c")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let justfile = root.appendingPathComponent("justfile")
        try "test:\n\techo test\n".write(to: justfile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertEqual(try JustfileService.discover(start: nested.path), justfile.path)
    }

    func testParseSourceRecipesAliasesAndDescriptions() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("justfile")
        try """
        # Start development
        dev:
            echo dev

        # Run quietly
        @run target="all":
            echo run

        alias r := run
        """.write(to: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let recipes = try JustfileService.parseSource(path: path.path)
        XCTAssertEqual(recipes.count, 3)
        XCTAssertEqual(recipes[0], Recipe(name: "dev", description: "Start development", sourceLine: 2))
        XCTAssertEqual(recipes[1], Recipe(
            name: "run",
            description: "Run quietly",
            parameters: ["target=\"all\""],
            sourceLine: 6
        ))
        XCTAssertEqual(recipes[2].name, "r")
    }

    func testJustSummaryIsAuthoritativeAndSourceAddsMetadata() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let justfile = directory.appendingPathComponent("justfile")
        try "# Local recipe\nlocal:\n\techo local\n".write(to: justfile, atomically: true, encoding: .utf8)

        let fakeJust = directory.appendingPathComponent("just")
        try "#!/bin/sh\nprintf 'local imported-run alias-run\\n'\n".write(to: fakeJust, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fakeJust.path)

        let recipes = try JustfileService.parse(path: justfile.path, justExecutable: fakeJust.path)
        XCTAssertEqual(recipes.map(\.name), ["local", "imported-run", "alias-run"])
        XCTAssertEqual(recipes[0].description, "Local recipe")
        XCTAssertEqual(recipes[1].description, "")
    }
}
