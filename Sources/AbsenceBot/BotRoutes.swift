import ApplicativeRouter
import Foundation
import Prelude
import Optics
import UrlFormEncoding

public protocol DerivePartialIsos {}

public enum Route: DerivePartialIsos, Equatable {
  case hello
  case slack(InteractiveMessageAction)
  case dialogflow(Webhook)
  case report(year: Int, month: Int)
}

private let routers: [Router<Route>] = [
  // Matches: GET /hello
  .hello
    <¢> get %> lit("hello") <% end,

  // Matches: GET /report/:year/:month
  .report
    <¢> get %> lit("report") %> pathParam(.int) <%> pathParam(.int) <% end,

  // Matches: POST /slack
  .slack
    <¢> post %> lit("slack")
      %> formField("payload", PartialIso.data
        >>> PartialIso.codableToJsonData(InteractiveMessageAction.self, encoder: slackJsonEncoder).inverted)
      <% end,

  // Matches: POST /dialogflow
  .dialogflow
    <¢> post %> lit("dialogflow")
      %> jsonBody(Webhook.self, encoder: dialogflowJsonEncoder, decoder: dialogflowJsonDecoder)
      <% end,
]

public let router = routers.reduce(.empty, <|>)
