import ApplicativeRouter
import Foundation
import Prelude

public protocol DerivePartialIsos {}

public enum Route: DerivePartialIsos, Equatable {
    case hello
    case slack
    case dialogflow(Dialogflow)
}

private let routers: [Router<Route>] = [
    // Matches: GET /hello
    .hello
        <¢> get %> lit("hello") <% end,
    
    // Matches: GET /slack
    .slack
        <¢> post %> lit("slack") <% end,

    // Matches: GET /dialogflow
    .dialogflow
      <¢> post %> lit("dialogflow") %> jsonBody(Dialogflow.self) <% end,
]

public let router = routers.reduce(.empty, <|>)


public struct Dialogflow: Codable, Equatable {
  var id: Int
  var name: String
}
