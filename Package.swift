// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OOMenuBar",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "OOMenuBar",
            path: "Sources/OOMenuBar"
        )
    ]
)
