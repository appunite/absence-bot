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
    .package(url: "https://github.com/pointfreeco/swift-web.git", .revision("b896eb4806412c998a75b4954dfbebbc42ad294c")),
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .branch("8cbc934")),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.2.0"),
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
        "SwiftJWT"
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
