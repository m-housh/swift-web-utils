// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "swift-web-utils",
  platforms: [
    .macOS(.v10_13)
  ],
  products: [
    .library(name: "RouterUtils", targets: ["RouterUtils"])
  ],
  dependencies: [
    .package(
      name: "Web", url: "https://github.com/pointfreeco/swift-web.git", .revision("616f365")),
    .package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-nonempty.git", from: "0.3.1"),
  ],
  targets: [
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
