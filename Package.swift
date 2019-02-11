// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "AbsenceBot",
  products: [
    .library(name: "AbsenceBot", targets: ["AbsenceBot"]),
    .executable(name: "Server", targets: ["Server"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-web.git", .revision("5dbbbf1")),
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .branch("8cbc934")),
    .package(url: "https://github.com/IBM-Swift/Swift-JWT.git", .branch("master")),
    .package(url: "https://github.com/Flight-School/MessagePack.git", .branch("master"))
  ],
  targets: [
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
        "MessagePack"
      ]
    ),

    .target(
      name: "Server",
      dependencies: ["AbsenceBot"]),

    .testTarget(
      name: "AbsenceBotTests",
      dependencies: ["AbsenceBot"]),
    ]
)
