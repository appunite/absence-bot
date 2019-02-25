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
  fetchEventsMiddleware
    >>> basicAuth(
      user: Current.envVars.basicAuth.username,
      password: Current.envVars.basicAuth.password)
    <| respond(.ok, encoder: dialogflowJsonEncoder)

private func fetchEventsMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, GoogleCalendar.EventsEnvelope, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, ReportFilter, Data> {
  
  return { conn in
    return Current.calendar.fetchAuthToken()
      .run
      .flatMap { errorOrToken in
        switch errorOrToken {
        case let .right(.right(token)):
          let dateInterval = DateInterval(
            start: .init(timeIntervalSince1970: 1548979200),
            end: .init(timeIntervalSince1970: 1551398399)
          )

          return Current.calendar.fetchEvents(token, dateInterval)
            .run
            .flatMap { errorOrEvent in
              switch errorOrEvent {
              case let .left(e):
                return conn
                  |> internalServerError(respond(text: e.localizedDescription))
              case let .right(envelope):
                return conn.map(const(envelope))
                  |> middleware
              }
          }
        default:
          fatalError()
        }
    }
  }
}
