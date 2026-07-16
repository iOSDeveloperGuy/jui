import Foundation

public enum Renderer {
    public static let selectedRowWidth = 96
    public static let minNameColumnWidth = 24
    public static let maxNameColumnWidth = 40
    public static let rowPrefixWidth = 3
    public static let rowGapWidth = 2
    public static let reservedScreenRows = 5
    public static let minimumDescriptionWidth = 12
    public static let minimumCompactNameWidth = 8

    public static func render(model: inout AppModel, rows: Int, columns: Int) -> String {
        let rowWidth = rowWidthForTerminal(columns)
        let capacity = recipeViewportCapacity(rows)
        let range = viewportRange(
            total: model.visible.count,
            selected: model.selected,
            offset: model.offset,
            capacity: capacity
        )
        model.offset = range.lowerBound

        var output = "\u{001B}[2J\u{001B}[H"
        let pathWidth = max(0, rowWidth - "jui  ".count)
        output += "\u{001B}[1;36mjui\u{001B}[0m  \u{001B}[2m\(truncateText(model.path, width: pathWidth))\u{001B}[0m\n"

        let search = model.query.isEmpty ? "Search: type to filter recipes" : "Search: \(model.query)_"
        output += "\u{001B}[2m\(truncateText(search, width: rowWidth))\u{001B}[0m\n\n"

        if model.visible.isEmpty {
            output += "\(truncateText("  No matching recipes", width: rowWidth))\n"
        } else {
            let nameWidth = fitNameColumnWidth(recipes: model.visible, rowWidth: rowWidth)
            let descriptionWidth = max(0, rowWidth - rowPrefixWidth - nameWidth - rowGapWidth)

            for absoluteIndex in range {
                let recipe = model.visible[absoluteIndex]
                let marker = resultMarker(model.results[recipe.name] ?? .notStarted)
                let name = truncateText(recipe.name, width: nameWidth)
                let description = truncateText(
                    recipe.description.isEmpty ? "No description" : recipe.description,
                    width: descriptionWidth
                )
                let row = padText(
                    " \(marker) \(padText(name, width: nameWidth))  \(padText(description, width: descriptionWidth))",
                    width: rowWidth
                )

                if absoluteIndex == model.selected {
                    output += "\u{001B}[1;7m\(row)\u{001B}[0m\n"
                } else {
                    output += " \(coloredMarker(model.results[recipe.name] ?? .notStarted)) "
                    output += "\u{001B}[36m\(padText(name, width: nameWidth))\u{001B}[0m  "
                    output += "\u{001B}[2m\(padText(description, width: descriptionWidth))\u{001B}[0m\n"
                }
            }
        }

        var footer = model.status
        if model.visible.count > capacity, !range.isEmpty {
            footer += "  \(range.lowerBound + 1)-\(range.upperBound)/\(model.visible.count)"
        }
        output += "\n\u{001B}[2m\(truncateText(footer, width: rowWidth))\u{001B}[0m"
        return output
    }

    public static func rowWidthForTerminal(_ columns: Int) -> Int {
        guard columns > 1 else { return 1 }
        return min(columns - 1, selectedRowWidth)
    }

    public static func recipeViewportCapacity(_ rows: Int) -> Int {
        max(1, rows - reservedScreenRows)
    }

    public static func viewportRange(
        total: Int,
        selected: Int,
        offset: Int,
        capacity: Int
    ) -> Range<Int> {
        guard total > 0 else { return 0..<0 }

        let safeCapacity = max(1, capacity)
        let safeSelected = min(max(0, selected), total - 1)
        let maxStart = max(0, total - safeCapacity)
        var start = min(max(0, offset), maxStart)

        if safeSelected < start {
            start = safeSelected
        } else if safeSelected >= start + safeCapacity {
            start = safeSelected - safeCapacity + 1
        }
        start = min(start, maxStart)
        return start..<min(total, start + safeCapacity)
    }

    public static func fitNameColumnWidth(recipes: [Recipe], rowWidth: Int) -> Int {
        var width = max(minNameColumnWidth, recipes.map { $0.name.count }.max() ?? 0)
        width = min(width, maxNameColumnWidth)

        var maximum = rowWidth - rowPrefixWidth - rowGapWidth - minimumDescriptionWidth
        if maximum < minimumCompactNameWidth {
            maximum = rowWidth - rowPrefixWidth - rowGapWidth
        }
        maximum = max(1, maximum)
        return min(width, maximum)
    }

    public static func truncateText(_ value: String, width: Int) -> String {
        guard width > 0 else { return "" }
        guard value.count > width else { return value }
        guard width > 1 else { return "…" }
        return String(value.prefix(width - 1)) + "…"
    }

    public static func padText(_ value: String, width: Int) -> String {
        let truncated = truncateText(value, width: width)
        return truncated + String(repeating: " ", count: max(0, width - truncated.count))
    }

    public static func resultMarker(_ result: RunResult) -> String {
        switch result {
        case .succeeded: return "✓"
        case .failed: return "✗"
        case .stopped: return "■"
        case .notStarted: return " "
        }
    }

    private static func coloredMarker(_ result: RunResult) -> String {
        switch result {
        case .succeeded: return "\u{001B}[1;32m✓\u{001B}[0m"
        case .failed: return "\u{001B}[1;31m✗\u{001B}[0m"
        case .stopped: return "\u{001B}[1;33m■\u{001B}[0m"
        case .notStarted: return " "
        }
    }
}
