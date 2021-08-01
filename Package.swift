// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "swift-web-utils",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "DatabaseUtils", targets: ["DatabaseUtils"]),
    .library(name: "RouterUtils", targets: ["RouterUtils"])
  ],
  dependencies: [
    .package(
      name: "Web", url: "https://github.com/pointfreeco/swift-web.git", .revision("616f365")),
    .package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-nonempty.git", from: "0.3.1"),
    .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0"),
    .package(name: "Prelude", url: "https://github.com/pointfreeco/swift-prelude.git", .revision("9240a1f")),
    .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.0.0"),
  ],
  targets: [
    .target(
      name: "DatabaseUtils",
      dependencies: [
        .product(name: "Either", package: "Prelude"),
        .product(name: "NonEmpty", package: "swift-nonempty"),
        .product(name: "SQLKit", package: "sql-kit")
      ]
    ),
    .testTarget(
      name: "DatabaseUtilsTests",
      dependencies: [
        "DatabaseUtils",
        .product(name: "SQLiteKit", package: "sqlite-kit")
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
  ]
)
