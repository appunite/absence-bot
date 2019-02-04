import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple

let absenceRequestDialogflowMiddleware: Middleware<StatusLineOpen, ResponseEnded, Webhook, Data> =
  fulfillmentMiddleware
    >>> fetchSlackUserMiddleware
    >>> basicAuth(
      user: Current.envVars.basicAuth.username,
      password: Current.envVars.basicAuth.password)
    <| writeStatus(.ok) >=> respond(encoder: JSONEncoder())


private func fulfillmentMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, Fulfillment, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<Webhook, Slack.User>, Data> {
  
  return { conn in
    let (dialogflow, user) = (get1(conn.data), rest(conn.data))
    
    switch interprete(payload: dialogflow, user: user) {
    case let .complete(request, fulfillment):
      let period = request.period
        .dates(timeZone: Current.hqTimeZone())
        .joined(separator: " - ")
      
      let message = Slack.Message
        .announcementMessage(callbackId: "x", requester: user.id, period: period, reason: request.reason.rawValue)
      
      return Current.slack.postMessage(message)
        .run // todo: try to better handle this error
        .flatMap { _ in
          return conn.map(const(fulfillment))
            |> middleware
      }
    case let .incomplete(fulfillment):
      return conn.map(const(fulfillment))
        |> middleware
    case .report(_, _):
      fatalError()
    }
  }
}

private func fetchSlackUserMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<Webhook, Slack.User>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, Webhook, Data> {
  
  return { conn in
    guard let user = conn.data.user else {
      return conn
        |> writeStatus(.internalServerError)
        >=> respond(text: "Missing slack user.")
    }
    
    return Current.slack.fetchUser(user)
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case let .right(.right(payload)):
          return conn.map(const(conn.data .*. payload.user))
            |> middleware
          
        case let .right(.left(e)):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.error)
          
        case let .left(e):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.localizedDescription)
        }
    }
  }
}
