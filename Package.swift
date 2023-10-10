// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-state-store",
  platforms: [
    // Add iOS, watchOS, and macOS versions
    .iOS(.v15),
    .watchOS(.v8),
    .macOS(.v10_15),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "StateStore",
      targets: ["StateStore"])
  ],
  dependencies: [
    // Add this line to include the `swift-log` package
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "StateStore",
      dependencies: [
        // Add `Logging` as a dependency for your target
        .product(name: "Logging", package: "swift-log")
      ]),
    .testTarget(
      name: "StateStoreTests",
      dependencies: ["StateStore"]),
  ]
)
