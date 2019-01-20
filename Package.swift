// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AbsenceBot",
  products: [
    .library(name: "AbsenceBot", targets: ["AbsenceBot"]),
    .executable(name: "Server", targets: ["Server"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-web.git", .branch("0243fbe")),
    .package(url: "https://github.com/pointfreeco/swift-prelude.git", .branch("8cbc934")),
    .package(url: "https://github.com/IBM-Swift/Swift-JWT.git", .branch("master"))
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
        "SwiftJWT"
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
