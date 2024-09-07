// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "RetryOnFailure",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "RetryOnFailure",
            targets: ["RetryOnFailure"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "RetryOnFailureMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "RetryOnFailure",
            dependencies: ["RetryOnFailureMacros"],
            swiftSettings: [
                .enableExperimentalFeature("BodyMacros")
            ]
        ),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(
            name: "RetryOnFailureClient",
            dependencies: ["RetryOnFailure"]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "RetryOnFailureTests",
            dependencies: [
                "RetryOnFailureMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
