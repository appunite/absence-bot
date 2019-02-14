import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple

let dialogflowMiddleware: Middleware<StatusLineOpen, ResponseEnded, Webhook, Data> =
  messageMiddleware
    >>> fulfillmentMiddleware
    >>> slackUserMiddleware
    >>> basicAuth(
      user: Current.envVars.basicAuth.username,
      password: Current.envVars.basicAuth.password)
    <| writeStatus(.ok) >=> respond(encoder: JSONEncoder())

private func messageMiddleware(
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

private func slackUserMiddleware(
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

private func fulfillmentMiddleware(
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
      
      guard let period = period(parameters: followupContext.parameters, tz: user.tz)
        else { return middleware <| conn.map(const(Fulfillment.missingPeriod .*. nil)) }
      
      if case .accept = payload.action {
        // we're done, send thanks comment and clear out contextes
        let fulfillment = Fulfillment.compliments(contexts: [
          payload.fullContext(lifespanCount: 0, params: .init()),
          payload.followupContext(lifespanCount: 0, params: .init())]
        )
        
        return middleware
          <| conn.map(const(fulfillment .*. .init(requester: .right(user), period: period, reason: reason, reviewer: nil)))
      }
      
      // we have all date, let's ask user if everytking is ok
      let fulfillment = Fulfillment
        .confirmation(
          absence: .init(requester: .right(user), period: period, reason: reason, reviewer: nil),
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