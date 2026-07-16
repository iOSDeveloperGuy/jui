import XCTest
@testable import JUICore

final class AppModelTests: XCTestCase {
    func testFilteringMatchesNamesAndDescriptionsAsSubsequence() {
        var model = AppModel(path: "/tmp/justfile", recipes: [
            Recipe(name: "build", description: "Build the application"),
            Recipe(name: "dev-clean", description: "Reset and start development"),
            Recipe(name: "test", description: "Run the test suite")
        ])

        for byte in "dcl".utf8 {
            model.append(byte: byte)
        }

        XCTAssertEqual(model.visible.map(\.name), ["dev-clean"])
        XCTAssertEqual(model.selected, 0)
        XCTAssertEqual(model.offset, 0)
    }

    func testBackspaceAndClearRestoreRecipes() {
        var model = AppModel(path: "/tmp/justfile", recipes: [Recipe(name: "dev"), Recipe(name: "test")])
        model.append(byte: Character("t").asciiValue!)
        XCTAssertEqual(model.visible.map(\.name), ["test"])

        model.backspace()
        XCTAssertEqual(model.visible.count, 2)

        model.append(byte: Character("d").asciiValue!)
        model.clearQuery()
        XCTAssertEqual(model.visible.count, 2)
    }
}
