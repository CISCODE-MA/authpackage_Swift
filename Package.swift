// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthPackage",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "AuthPackage", targets: ["AuthPackage"]),
        .library(name: "AuthPackageUI", targets: ["AuthPackageUI"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AuthPackage",
            dependencies: [],
            path: "Sources/AuthPackage"
        ),
        .target(
            name: "AuthPackageUI",
            dependencies: ["AuthPackage"],
            path: "Sources/AuthPackageUI"
        ),
        .testTarget(
            name: "AuthPackageTests",
            dependencies: ["AuthPackage", "AuthPackageUI"],
            path: "Tests/AuthPackageTests"
        ),
        .testTarget(
            name: "AuthPackageLiveTests",
            dependencies: ["AuthPackage"]

        ),
    ]
)
