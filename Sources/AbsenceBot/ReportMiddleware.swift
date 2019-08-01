import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple

public struct ReportFilter {
  public var year: Int
  public var month: Int
//  public var reason: Set<Absence.Reason>?
}

extension ReportFilter: Codable, Equatable {}

let reportMiddleware: Middleware<StatusLineOpen, ResponseEnded, ReportFilter, Data> =
  fetchEventsMiddleware
    >>> fetchGoogleTokenMiddleware
    >>> basicAuth(
      user: Current.envVars.basicAuth.username,
      password: Current.envVars.basicAuth.password)
    <| respond(.ok, encoder: reportJsonEncoder)

private func fetchEventsMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, [ReportResult], Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<ReportFilter, GoogleCalendar.AccessToken>, Data> {
  
  return { conn in
    let (filter, token) = (get1(conn.data), rest(conn.data))

    guard let dateInterval = DateInterval(year: filter.year, month: filter.month)
      else { return conn |> unprocessableEntityError(respond(text: "Missing or invalid params.")) }

    return Current.calendar.fetchEvents(token, dateInterval)
      .run
      .flatMap { errorOrEvent in
        switch errorOrEvent {
        case let .left(e):
          return conn
            |> internalServerError(respond(text: e.localizedDescription))
        case let .right(envelope):
          let predicate: Set<Absence.Reason> = /*filter.reason ?? */[.illness, .holiday, .conference]
          let events = envelope.events
            .map(ReportResult.init)
            .filter { predicate.contains($0.reason!) }
          
          return conn.map(const(events))
            |> middleware
        }
    }
  }
}

private func fetchGoogleTokenMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<ReportFilter, GoogleCalendar.AccessToken>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, ReportFilter, Data> {
  
  return { conn in
    return Current.calendar.fetchAuthToken()
      .run
      .flatMap { errorOrToken in
        switch errorOrToken {
        case let .right(.right(token)):
          return conn.map(const(conn.data .*. token))
            |> middleware
        default:
          return conn |> unprocessableEntityError(respond(text: "Can't fetch google token."))
        }
    }
  }
}

private let reportJsonEncoder = JSONEncoder()
  |> \.dateEncodingStrategy .~ .formatted(dateFormatter)
  |> sortedKeysOutputFormatting

private let dateFormatter = DateFormatter()
  |> iso8601
  |> \.calendar .~ Calendar(identifier: .iso8601)
  |> \.timeZone .~ Current.calendarTimeZone()
  |> \.dateFormat .~ "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

