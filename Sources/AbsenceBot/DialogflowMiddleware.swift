import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple

let absenceRequestDialogflowMiddleware: Middleware<StatusLineOpen, ResponseEnded, Webhook, Data> =
  fulfillmentMiddleware
    >>> interpreterMiddleware
    >>> fetchSlackUserMiddleware
    >>> basicAuth(
      user: Current.envVars.basicAuth.username,
      password: Current.envVars.basicAuth.password)
    <| writeStatus(.ok) >=> respond(encoder: JSONEncoder())

private func fulfillmentMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, Fulfillment, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<Fulfillment, Absence?>, Data> {
  
  return { conn in
    let (fulfillment, _absence) = (get1(conn.data), rest(conn.data))

    guard let absence = _absence else {
      return conn.map(const(fulfillment))
        |> middleware
    }

    return Current.slack.postMessage(.announcementMessage(absence: absence))
      .run // todo: try to better handle this error
      .flatMap { _ in
        return conn.map(const(fulfillment))
          |> middleware
    }
  }
}

private func fetchSlackUserMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<Webhook, Slack.User>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, Webhook, Data> {
  
  return { conn in
    guard let user = conn.data.user else {
      return conn
        |> internalServerError(respond(text: "Missing slack user."))
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
            |> internalServerError(respond(text: e.error))
          
        case let .left(e):
          return conn
            |> internalServerError(respond(text: e.localizedDescription))
        }
    }
  }
}
