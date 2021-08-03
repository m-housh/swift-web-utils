// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "swift-web-utils",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "DatabaseUtils", targets: ["DatabaseUtils"]),
    .library(name: "MiddlewareUtils", targets: ["MiddlewareUtils"]),
    .library(name: "RouterUtils", targets: ["RouterUtils"]),
    .library(name: "TestUtils", targets: ["TestUtils"]),
  ],
  dependencies: [
    .package(
      name: "Web", url: "https://github.com/pointfreeco/swift-web.git", .revision("616f365")),
    .package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-nonempty.git", from: "0.3.1"),
    .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0"),
    .package(
      name: "Prelude", url: "https://github.com/pointfreeco/swift-prelude.git", .revision("9240a1f")
    ),
    .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.0.0"),
    .package(
      name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
      from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "DatabaseUtils",
      dependencies: [
        .product(name: "Either", package: "Prelude"),
        .product(name: "NonEmpty", package: "swift-nonempty"),
        .product(name: "SQLKit", package: "sql-kit"),
      ]
    ),
    .testTarget(
      name: "DatabaseUtilsTests",
      dependencies: [
        "DatabaseUtils",
        .product(name: "SQLiteKit", package: "sqlite-kit"),
      ]
    ),
    .target(
      name: "MiddlewareUtils",
      dependencies: [
        .product(name: "Either", package: "Prelude"),
        .product(name: "HttpPipeline", package: "Web"),
        .product(name: "Prelude", package: "Prelude"),
      ]
    ),
    .testTarget(
      name: "MiddlewareUtilsTests",
      dependencies: [
        "MiddlewareUtils",
        "RouterUtils",
        .product(name: "ApplicativeRouterHttpPipelineSupport", package: "Web"),
        .product(name: "HttpPipelineTestSupport", package: "Web"),
        .product(name: "SnapshotTesting", package: "SnapshotTesting"),
      ]
    ),
    .target(
      name: "RouterUtils",
      dependencies: [
        .product(name: "ApplicativeRouter", package: "Web"),
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "NonEmpty", package: "swift-nonempty"),
      ]
    ),
    .testTarget(
      name: "RouterUtilsTests",
      dependencies: ["RouterUtils"]
    ),
    .target(
      name: "TestUtils",
      dependencies: [
        .product(name: "Either", package: "Prelude"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
      ]
    ),
  ]
)
