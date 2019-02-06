import Foundation
import HttpPipeline
import Prelude
import Optics
import Tuple

public func internalServerError<A>(_ middleware: @escaping Middleware<HeadersOpen, ResponseEnded, A, Data>)
  -> Middleware<StatusLineOpen, ResponseEnded, A, Data> {
    return writeStatus(.internalServerError)
      >=> middleware
}

public func unprocessableEntityError<A>(_ middleware: @escaping Middleware<HeadersOpen, ResponseEnded, A, Data>)
  -> Middleware<StatusLineOpen, ResponseEnded, A, Data> {
    return writeStatus(.unprocessableEntity)
      >=> middleware
}

public func interpreterMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<Fulfillment, Absence?>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<Webhook, Slack.User>, Data> {
  return { conn in
    let (payload, user) = (get1(conn.data), rest(conn.data))
    
    switch payload.action {
    case .full, .fillDate, .accept:
      guard let followupContext = payload.followupContext
        else { return conn |> unprocessableEntityError(respond(text: "Missing followup context.")) }
      
      guard let reason = followupContext.parameters.reason.flatMap(Absence.Reason.init)
        else { return middleware <| conn.map(const(Fulfillment.missingReason .*. nil)) }

      guard let period = period(parameters: followupContext.parameters, tz: user.timezone)
        else { return middleware <| conn.map(const(Fulfillment.missingPeriod .*. nil)) }
      
      if case .accept = payload.action {
        // we're done, send thanks comment and clear out contextes
        let fulfillment = Fulfillment.compliments(contexts: [
          payload.fullContext(lifespanCount: 0, params: .init()),
          payload.followupContext(lifespanCount: 0, params: .init())]
        )
        
        return middleware
          <| conn.map(const(fulfillment .*. .init(user: user, period: period, reason: reason)))
      }

      // we have all date, let's ask user if everytking is ok
      let fulfillment = Fulfillment
        .confirmation(
          absence: .init(user: user, period: period, reason: reason),
          context: payload.fullContext(lifespanCount: 2, params: followupContext.parameters))

      return middleware
        <| conn.map(const(fulfillment .*. nil))
    }
  }
}
private func period(parameters: Context.Parameters, tz: TimeZone) -> Absence.Period? {
  // single day absence
  if let date = parameters.date {
    // if there is no information about time, just treat this as full day
    guard let timeStart = parameters.timeStart, let timeEnd = parameters.timeEnd
      else { return Absence.Period(dates: (date, date), tz: tz) }
    
    // extend day with time information
    return zip(with: { Absence.Period(dates: ($0, $1), tz: tz) })(
      date.dateByReplacingTime(from: timeStart),
      date.dateByReplacingTime(from: timeEnd)
    )
  }
  
  // date time period
  if let start = parameters.dateTimeStart, let end = parameters.dateTimeEnd {
    return .init(dates: (start, end), tz: tz)
  }
  
  // period absence
  if let period = parameters.datePeriod {
    return .init(dates: (period.startDate, period.endDate), tz: tz)
  }
  
  // date period
  if let start = parameters.dateStart, let end = parameters.dateEnd {
    return .init(dates: (start, end), tz: tz)
  }
  
  // mixed date & date time period
  if let start = parameters.dateTimeStart, let end = parameters.dateEnd {
    // todo: I need to change end-time to 17:00
    return .init(dates: (start, end), tz: tz)
  }
  
  // mixed date & date time period
  if let start = parameters.dateStart, let end = parameters.dateTimeEnd {
    // todo: I need to change start-time to 8:00
    return .init(dates: (start, end), tz: tz)
  }
  
  // some error occured
  return nil
}

extension Webhook {
  internal var followupContext: Context? {
    return self.outputContexts
      .first { $0.identifier == .followup }
  }
  
  internal var fullContext: Context? {
    return self.outputContexts
      .first { $0.identifier == .full }
  }
  
  internal func fullContext(lifespanCount: Int, params: Context.Parameters) -> Context {
    let name = Context.name(session: self.session, identifier: .full)
    return .init(name: name, lifespanCount: lifespanCount, parameters: params)
  }
  
  internal func followupContext(lifespanCount: Int, params: Context.Parameters) -> Context {
    let name = Context.name(session: self.session, identifier: .followup)
    return .init(name: name, lifespanCount: lifespanCount, parameters: params)
  }
}

extension Context {
  internal static func name(session: URL, identifier: Context.Identifier) -> URL {
    return session
      .appendingPathComponent("contexts")
      .appendingPathComponent(identifier.rawValue)
  }
}

