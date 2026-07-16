import Foundation

public enum JUIError: LocalizedError {
    case executableNotFound(String)
    case noJustfile
    case noRecipes(String)
    case commandFailed(String)
    case terminal(String)

    public var errorDescription: String? {
        switch self {
        case .executableNotFound(let executable):
            return "\(executable) is not installed or not on PATH"
        case .noJustfile:
            return "no justfile found in this directory or any parent"
        case .noRecipes(let path):
            return "no recipes found in \(path)"
        case .commandFailed(let message):
            return message
        case .terminal(let message):
            return message
        }
    }
}
