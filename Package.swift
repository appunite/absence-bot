// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "AbsenceBot",
  products: [
    .library(name: "AbsenceBot", targets: ["AbsenceBot"]),
    .library(name: "AbsenceBotTestSupport", targets: ["AbsenceBotTestSupport"]),
    .executable(name: "Server", targets: ["Server"]),
  ],
  dependencies: [
    .package(url: "https://github.com/emilwojtaszek/swift-web.git", .branch("swift-snapshot-testing-1.5.0")),
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .revision("6e426b0")),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .exact("1.5.0")),
    .package(url: "https://github.com/pointfreeco/swift-tagged.git", .branch("master")),
    .package(url: "https://github.com/IBM-Swift/Swift-JWT.git", .branch("master"))
  ],
  targets: [
    .target(
      name: "Server",
      dependencies: ["AbsenceBot"]),

    .target(
      name: "AbsenceBot",
      dependencies: [
        "ApplicativeRouter",
        "ApplicativeRouterHttpPipelineSupport",
        "Either",
        "HttpPipeline",
        "Optics",
        "Tuple",
        "UrlFormEncoding",
        "SwiftJWT",
        "Tagged"
      ]
    ),

    .target(
      name: "AbsenceBotTestSupport",
      dependencies: [
        "Either",
        "HttpPipelineTestSupport",
        "AbsenceBot",
        "Prelude",
        "SnapshotTesting",
        ]
    ),

    .testTarget(
      name: "AbsenceBotTests",
      dependencies: [
        "HttpPipelineTestSupport",
        "AbsenceBot",
        "AbsenceBotTestSupport"
      ]
    )
  ]
)
