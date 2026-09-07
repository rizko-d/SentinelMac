// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SentinelMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SentinelMac", targets: ["SentinelMac"]),
        .library(name: "SentinelCore", targets: ["SentinelCore"])
    ],
    targets: [
        .target(
            name: "SentinelCore",
            path: "Sources/SentinelCore"
        ),
        .executableTarget(
            name: "SentinelMac",
            dependencies: ["SentinelCore"],
            path: "Sources/SentinelMac"
        ),
        .testTarget(
            name: "SentinelCoreTests",
            dependencies: ["SentinelCore"],
            path: "Tests/SentinelCoreTests"
        )
    ]
)
