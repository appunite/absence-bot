import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple


struct ReportFilter {
  let year: Int
  let mont: Int
}

let reportMiddleware: Middleware<StatusLineOpen, ResponseEnded, ReportFilter, Data> =
  slackUserMiddleware
    >>> basicAuth(
      user: Current.envVars.basicAuth.username,
      password: Current.envVars.basicAuth.password)
    <| respond(.ok, encoder: dialogflowJsonEncoder)

private func slackUserMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, [Absence], Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, ReportFilter, Data> {
  
  return { conn in
    return Current.calendar..fetchUser(conn.data.user)
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
