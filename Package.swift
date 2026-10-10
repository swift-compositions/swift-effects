// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-effects",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Effects",
            targets: ["Effects"]
        ),
        .library(
            name: "Effects Built-in",
            targets: ["Effects Built-in"]
        ),
        .library(
            name: "Effects Testing",
            targets: ["Effects Testing"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-effect.git", branch: "main", traits: ["Dependency"]),
        .package(
            url: "https://github.com/swift-atoms/swift-dependency.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-witness.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-async.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-compositions/swift-clocks.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Effects",
            dependencies: [
                .product(name: "Effect", package: "swift-effect"),
                .product(name: "Dependency", package: "swift-dependency"),
            ]
        ),
        .target(
            name: "Effects Built-in",
            dependencies: [
                .product(name: "Effect", package: "swift-effect"),
                .product(name: "Dependency", package: "swift-dependency"),
                .target(name: "Effects"),
                .product(name: "Witness", package: "swift-witness"),
            ]
        ),
        .target(
            name: "Effects Testing",
            dependencies: [
                .product(name: "Effect", package: "swift-effect"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Async", package: "swift-async"),
                .product(name: "Clocks", package: "swift-clocks"),
            ]
        ),
        .testTarget(
            name: "Effects Tests",
            dependencies: [
                .product(name: "Dependency", package: "swift-dependency"),
                .product(name: "Effect", package: "swift-effect"),
                .target(name: "Effects"),
                .target(name: "Effects Testing"),
            ]
        ),
        .testTarget(
            name: "Effects Built-in Tests",
            dependencies: [
                .product(name: "Effect", package: "swift-effect"),
                .target(name: "Effects Built-in"),
                .target(name: "Effects Testing"),
                .product(name: "Async", package: "swift-async"),
            ]
        ),
        .testTarget(
            name: "Effects Testing Tests",
            dependencies: [
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Effect", package: "swift-effect"),
                .target(name: "Effects Testing")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableExperimentalFeature("Lifetimes"),
        .treatAllWarnings(as: .error),
    ]
}
