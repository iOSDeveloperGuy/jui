import Foundation

public final class Application {
    private let justExecutable: String
    private var model: AppModel

    public init(justExecutable: String, justfilePath: String, recipes: [Recipe]) {
        self.justExecutable = justExecutable
        self.model = AppModel(path: justfilePath, recipes: recipes)
    }

    public func run() throws {
        let originalState = try Terminal.enableRawMode()
        Terminal.enterAlternateScreen()
        defer {
            Terminal.leaveAlternateScreen()
            Terminal.restore(originalState)
        }

        while true {
            let size = Terminal.dimensions()
            Terminal.write(Renderer.render(model: &model, rows: size.rows, columns: size.columns))

            switch try Terminal.readEvent() {
            case .controlC:
                return
            case .escape:
                if model.query.isEmpty {
                    return
                }
                model.clearQuery()
            case .arrowUp:
                model.moveUp()
            case .arrowDown:
                model.moveDown()
            case .backspace:
                model.backspace()
            case .character(let byte):
                model.append(byte: byte)
            case .enter:
                if let recipe = model.selectedRecipe {
                    try execute(recipe, originalState: originalState)
                }
            case .unknown:
                continue
            }
        }
    }

    private func execute(_ recipe: Recipe, originalState: TerminalState) throws {
        Terminal.restore(originalState)
        Terminal.leaveAlternateScreen()
        Terminal.write("Running \u{001B}[1mjust \(recipe.name)\u{001B}[0m\n\n")

        let execution = RecipeRunner.run(
            justExecutable: justExecutable,
            justfilePath: model.path,
            recipe: recipe
        )
        model.record(execution.result, for: recipe, status: execution.status)

        Terminal.write("\n\(execution.status)\n")
        if execution.shouldPause {
            Terminal.write("Press Enter to return to jui...")
            _ = readLine()
        }

        _ = try Terminal.enableRawMode()
        Terminal.enterAlternateScreen()
    }
}
