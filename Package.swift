// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LucideIcons",
    platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15), .visionOS(.v1)],
    products: [.library(name: "LucideIcons", targets: ["LucideIcons"])],
    targets: [
        .target(
            name: "LucideIcons",
            resources: [.process("Resources")]
        ),
        .testTarget(name: "LucideIconsTests", dependencies: ["LucideIcons"]),
    ]
)
