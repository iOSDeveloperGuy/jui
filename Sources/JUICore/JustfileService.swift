import Foundation

public enum JustfileService {
    private static let names = ["justfile", "Justfile", ".justfile"]
    private static let recipePattern = try! NSRegularExpression(
        pattern: #"^@?([A-Za-z_][A-Za-z0-9_-]*)(?:\s+([^:]+))?:\s*(?:#.*)?$"#
    )
    private static let aliasPattern = try! NSRegularExpression(
        pattern: #"^alias\s+([A-Za-z_][A-Za-z0-9_-]*)\s*:=\s*[A-Za-z_][A-Za-z0-9_-]*\s*(?:#.*)?$"#
    )

    public static func discover(start: String, fileManager: FileManager = .default) throws -> String {
        var isDirectory: ObjCBool = false
        var current = URL(fileURLWithPath: start).standardizedFileURL

        if fileManager.fileExists(atPath: current.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            current.deleteLastPathComponent()
        }

        while true {
            for name in names {
                let candidate = current.appendingPathComponent(name)
                var candidateIsDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: candidate.path, isDirectory: &candidateIsDirectory),
                   !candidateIsDirectory.boolValue {
                    return candidate.path
                }
            }

            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                throw JUIError.noJustfile
            }
            current = parent
        }
    }

    public static func parse(path: String, justExecutable: String) throws -> [Recipe] {
        let metadataResult = Result { try parseSource(path: path) }
        let namesResult = Result { try listAvailableRecipes(path: path, justExecutable: justExecutable) }

        if case .success(let names) = namesResult {
            let metadata = (try? metadataResult.get()) ?? []
            let byName = Dictionary(uniqueKeysWithValues: metadata.map { ($0.name, $0) })
            let recipes = names.map { byName[$0] ?? Recipe(name: $0) }
            guard !recipes.isEmpty else {
                throw JUIError.noRecipes(path)
            }
            return recipes
        }

        let metadata = try metadataResult.get()
        guard !metadata.isEmpty else {
            let underlying = (try? namesResult.get())
            _ = underlying
            throw JUIError.noRecipes(path)
        }
        return metadata.sorted { $0.name < $1.name }
    }

    public static func parseSource(path: String) throws -> [Recipe] {
        let source = try String(contentsOfFile: path, encoding: .utf8)
        var recipes: [Recipe] = []
        var comments: [String] = []

        for (zeroBasedLine, lineSlice) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = String(lineSlice)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lineNumber = zeroBasedLine + 1

            if trimmed.hasPrefix("#") {
                comments.append(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
                continue
            }
            if trimmed.isEmpty {
                comments.removeAll(keepingCapacity: true)
                continue
            }
            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                continue
            }
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                continue
            }

            if let match = firstMatch(aliasPattern, in: line) {
                recipes.append(Recipe(
                    name: capture(match, group: 1, in: line),
                    description: comments.joined(separator: " ").trimmingCharacters(in: .whitespaces),
                    sourceLine: lineNumber
                ))
                comments.removeAll(keepingCapacity: true)
                continue
            }

            guard let match = firstMatch(recipePattern, in: line) else {
                comments.removeAll(keepingCapacity: true)
                continue
            }

            let parameterText = capture(match, group: 2, in: line)
            recipes.append(Recipe(
                name: capture(match, group: 1, in: line),
                description: comments.joined(separator: " ").trimmingCharacters(in: .whitespaces),
                parameters: parameterText.split(whereSeparator: { $0.isWhitespace }).map(String.init),
                sourceLine: lineNumber
            ))
            comments.removeAll(keepingCapacity: true)
        }

        return recipes
    }

    public static func listAvailableRecipes(path: String, justExecutable: String) throws -> [String] {
        let process = Process()
        let output = Pipe()
        let errors = Pipe()

        process.executableURL = URL(fileURLWithPath: justExecutable)
        process.arguments = ["--justfile", path, "--summary", "--unsorted"]
        process.currentDirectoryURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        process.standardOutput = output
        process.standardError = errors

        try process.run()
        process.waitUntilExit()

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = errors.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw JUIError.commandFailed(message?.isEmpty == false ? message! : "list recipes with just failed")
        }

        return String(data: outputData, encoding: .utf8)?
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init) ?? []
    }

    private static func firstMatch(_ regex: NSRegularExpression, in value: String) -> NSTextCheckingResult? {
        regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value))
    }

    private static func capture(_ match: NSTextCheckingResult, group: Int, in value: String) -> String {
        let range = match.range(at: group)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: value) else {
            return ""
        }
        return String(value[swiftRange])
    }
}
