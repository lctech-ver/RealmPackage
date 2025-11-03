// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RealmPackage",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RealmPackage",
            targets: ["RealmPackage"]),
    ],
    dependencies: [.package(url: "https://github.com/realm/realm-swift.git", exact: "20.0.3")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RealmPackage", dependencies: [.product(name: "RealmSwift", package: "realm-swift")]),
        .testTarget(
            name: "RealmPackageTests",
            dependencies: ["RealmPackage"]
        ),
    ]
)
