// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "jui",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "jui", targets: ["JUI"])
    ],
    targets: [
        .target(name: "JUICore"),
        .executableTarget(name: "JUI", dependencies: ["JUICore"]),
        .testTarget(name: "JUICoreTests", dependencies: ["JUICore"])
    ],
    swiftLanguageModes: [.v5]
)
