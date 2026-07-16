import XCTest
@testable import JUICore

final class RendererTests: XCTestCase {
    func testRecipeViewportCapacityReservesHeaderAndFooter() {
        XCTAssertEqual(Renderer.recipeViewportCapacity(24), 19)
        XCTAssertEqual(Renderer.recipeViewportCapacity(3), 1)
    }

    func testViewportRangeKeepsSelectionVisible() {
        XCTAssertEqual(Renderer.viewportRange(total: 50, selected: 0, offset: 0, capacity: 10), 0..<10)
        XCTAssertEqual(Renderer.viewportRange(total: 50, selected: 10, offset: 0, capacity: 10), 1..<11)
        XCTAssertEqual(Renderer.viewportRange(total: 50, selected: 25, offset: 1, capacity: 10), 16..<26)
        XCTAssertEqual(Renderer.viewportRange(total: 50, selected: 5, offset: 16, capacity: 10), 5..<15)
        XCTAssertEqual(Renderer.viewportRange(total: 50, selected: 49, offset: 16, capacity: 10), 40..<50)
    }

    func testRowWidthLeavesFinalTerminalColumnUnused() {
        XCTAssertEqual(Renderer.rowWidthForTerminal(80), 79)
        XCTAssertEqual(Renderer.rowWidthForTerminal(160), Renderer.selectedRowWidth)
    }

    func testNameColumnShrinksToPreserveDescriptionSpace() {
        let recipes = [Recipe(name: String(repeating: "a", count: Renderer.maxNameColumnWidth))]
        XCTAssertEqual(Renderer.fitNameColumnWidth(recipes: recipes, rowWidth: 40), 23)
    }

    func testPadTextUsesCharacters() {
        XCTAssertEqual(Renderer.padText("✓", width: 3), "✓  ")
    }
}
