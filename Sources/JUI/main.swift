import Foundation
import JUICore

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

func fatal(_ message: String) -> Never {
    FileHandle.standardError.write(Data("jui: \(message)\n".utf8))
    exit(1)
}

if CommandLine.arguments.dropFirst().contains("--version") {
    print("jui \(BuildInfo.version)")
    exit(0)
}

guard let justExecutable = ExecutableLocator.find("just") else {
    fatal("just is not installed or not on PATH")
}

do {
    let path = try JustfileService.discover(start: FileManager.default.currentDirectoryPath)
    let recipes = try JustfileService.parse(path: path, justExecutable: justExecutable)
    try Application(justExecutable: justExecutable, justfilePath: path, recipes: recipes).run()
} catch {
    fatal(error.localizedDescription)
}
