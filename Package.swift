// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftURLPattern",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v15), .tvOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "URLPattern",
            targets: ["URLPattern"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "URLPattern"),
        .testTarget(
            name: "URLPatternTests",
            dependencies: ["URLPattern"]
        ),
    ]
)
