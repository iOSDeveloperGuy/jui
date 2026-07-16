import Foundation

public struct AppModel: Sendable {
    public let path: String
    public let recipes: [Recipe]
    public private(set) var visible: [Recipe]
    public private(set) var selected: Int
    public var offset: Int
    public private(set) var query: String
    public var status: String
    public private(set) var results: [String: RunResult]

    public init(path: String, recipes: [Recipe]) {
        self.path = path
        self.recipes = recipes
        self.visible = recipes
        self.selected = 0
        self.offset = 0
        self.query = ""
        self.status = "type to search  ↑/↓ select  enter run  esc clear/quit  ctrl-c quit"
        self.results = [:]
    }

    public mutating func append(byte: UInt8) {
        guard byte >= 32, byte <= 126, let scalar = UnicodeScalar(Int(byte)) else {
            return
        }
        query.append(Character(scalar))
        filter()
    }

    public mutating func backspace() {
        guard !query.isEmpty else { return }
        query.removeLast()
        filter()
    }

    public mutating func clearQuery() {
        guard !query.isEmpty else { return }
        query = ""
        filter()
    }

    public mutating func moveUp() {
        if selected > 0 {
            selected -= 1
        }
    }

    public mutating func moveDown() {
        if selected + 1 < visible.count {
            selected += 1
        }
    }

    public mutating func record(_ result: RunResult, for recipe: Recipe, status: String) {
        results[recipe.name] = result
        self.status = status
    }

    public var selectedRecipe: Recipe? {
        guard visible.indices.contains(selected) else { return nil }
        return visible[selected]
    }

    private mutating func filter() {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        visible = recipes.filter {
            fuzzyContains(value: "\($0.name) \($0.description)".lowercased(), query: normalized)
        }
        selected = 0
        offset = 0
    }
}

public func fuzzyContains(value: String, query: String) -> Bool {
    guard !query.isEmpty else { return true }

    let queryCharacters = Array(query)
    var queryIndex = 0
    for character in value {
        if queryIndex < queryCharacters.count, character == queryCharacters[queryIndex] {
            queryIndex += 1
        }
    }
    return queryIndex == queryCharacters.count
}
