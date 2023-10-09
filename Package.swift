// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-sdk-generator",
  platforms: [.macOS("13.3")],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .executable(
      name: "swift-sdk-generator",
      targets: ["GeneratorCLI"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0"),
    .package(url: "https://github.com/apple/swift-system", from: "1.2.1"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
    .package(url: "https://github.com/apple/swift-async-algorithms.git", exact: "1.0.0-alpha"),
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.1.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.58.0"),
    .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.19.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
    .package(url: "https://github.com/apple/swift-foundation.git", revision: "62500a5"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .executableTarget(
      name: "GeneratorCLI",
      dependencies: [
        "SwiftSDKGenerator",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "FoundationInternationalization", package: "swift-foundation"),
      ]
    ),
    .target(
      name: "SwiftSDKGenerator",
      dependencies: [
        .target(name: "AsyncProcess"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "AsyncHTTPClient", package: "async-http-client"),
        .product(name: "SystemPackage", package: "swift-system"),
      ],
      exclude: ["Dockerfiles"]
    ),
    .testTarget(
      name: "SwiftSDKGeneratorTests",
      dependencies: [
        .target(name: "SwiftSDKGenerator"),
      ]
    ),
    .target(
      name: "AsyncProcess",
      dependencies: [
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "NIOExtras", package: "swift-nio-extras"),
        .product(name: "DequeModule", package: "swift-collections"),
        .product(name: "SystemPackage", package: "swift-system"),
      ]
    ),
    .testTarget(
      name: "AsyncProcessTests",
      dependencies: [
        "AsyncProcess",
        .product(name: "Atomics", package: "swift-atomics"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
  ]
)
