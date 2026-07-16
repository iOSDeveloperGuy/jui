import Foundation

public struct Recipe: Equatable, Sendable {
    public let name: String
    public let description: String
    public let parameters: [String]
    public let sourceLine: Int?

    public init(
        name: String,
        description: String = "",
        parameters: [String] = [],
        sourceLine: Int? = nil
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.sourceLine = sourceLine
    }
}

public enum RunResult: Equatable, Sendable {
    case notStarted
    case succeeded
    case failed(exitCode: Int32?)
    case stopped
}
