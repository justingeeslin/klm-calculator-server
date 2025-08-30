// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "KlmCalculatorServer",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/justingeeslin/Persona", branch: "develop"),
    ],
    targets: [
        .executableTarget(
            name: "KlmCalculatorServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Persona", package: "Persona"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "KlmCalculatorServerTests",
            dependencies: [
                .target(name: "KlmCalculatorServer"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
