// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "AbsenceBot",
  products: [
    .library(name: "AbsenceBot", targets: ["AbsenceBot"]),
    .library(name: "AbsenceBotTestSupport", targets: ["AbsenceBotTestSupport"]),
    .executable(name: "Server", targets: ["Server"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-web.git", .revision("5dbbbf1")),
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .branch("8cbc934")),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.1.0"),
    .package(url: "https://github.com/IBM-Swift/Swift-JWT.git", .branch("master")),
    .package(url: "https://github.com/emilwojtaszek/CodableCSV.git", .branch("swift-pm")),
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
        "CodableCSV"
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
