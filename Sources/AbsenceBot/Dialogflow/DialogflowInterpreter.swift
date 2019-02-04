import Foundation
import HttpPipeline
import Prelude
import Optics
import Tuple

private enum Action: String, Codable, Equatable {
  case full = "absenceday.absenceday-full"
  case fillDate = "absenceday.absenceday-fill-date"
  case accept = "absenceday.absenceday-yes"
}

public func interprete(payload: Webhook, user: Slack.User) -> Status {
  switch Action.init(rawValue: payload.action)! {
  case .full, .fillDate:
    let followupContextParams = payload.followupContext
      .map { $0.parameters }
    
    guard let reason = followupContextParams?.reason
      else { return .incomplete(Fulfillment(text: .raw("There is no reason value."))) }
    
    // we don't have any dates, we need to ask about them
    guard let period = followupContextParams?.period
      .flatMap (applyTimeZoneOffset(user.timezone))
      else { return .incomplete(Fulfillment(text: .missingPeriod)) }

    // we have all date, let's ask user if everytking is ok
    let fullContext = followupContextParams
      .flatMap { payload.fullContext(lifespanCount: 2, params: $0) }

    return .incomplete(Fulfillment(text: .confirmation(reason, period, user.timezone), contexts: [fullContext].compactMap {$0} ))

  case .accept:
    let followupContextParams = payload.followupContext
      .map { $0.parameters }
    
    guard let reason = followupContextParams?.reason
      else { return .incomplete(Fulfillment(text: .raw("There is no reason value."))) }
    
    guard let period = followupContextParams?.period
      .flatMap (applyTimeZoneOffset(user.timezone))
      else { return .incomplete(Fulfillment(text: .raw("There is no date defined."))) }
    
    // create full context with clear-out lifespan count
    let _fullContext = payload.fullContext(lifespanCount: 0, params: .init())
    
    // create followup context with clear-out lifespan count
    let _followupContext = payload.followupContext(lifespanCount: 0, params: .init())
    
    // we're done, send tanks comment and clear out contextes
    let absenceRequest = Absence(user: user, period: period, reason: Absence.Reason.init(rawValue: reason)!)
    return .complete(absenceRequest, Fulfillment(text: .thanks, contexts: [
      _fullContext, _followupContext].compactMap { $0 }))
  }
}

extension Context.Parameters {
  internal var period: Absence.Period? {
    // single day absence
    if let date = self.date {
      // if there is no information about time, just treat this as full day
      guard let timeStart = self.timeStart, let timeEnd = self.timeEnd
        else { return Absence.Period(dates: (date, date)) }
      
      // extend day with time information
      return zip(with: { Absence.Period(dates: ($0, $1)) })(
        date.dateByReplacingTime(from: timeStart),
        date.dateByReplacingTime(from: timeEnd)
      )
    }
    
    // date time period
    if let start = self.dateTimeStart, let end = self.dateTimeEnd {
      return .init(dates: (start, end))
    }
    
    // period absence
    if let period = self.datePeriod {
      return .init(dates: (period.startDate, period.endDate))
    }
    
    // date period
    if let start = self.dateStart, let end = self.dateEnd {
      return .init(dates: (start, end))
    }
    
    // mixed date & date time period
    if let start = self.dateTimeStart, let end = self.dateEnd {
      // todo: I need to change end-time to 17:00
      return .init(dates: (start, end))
    }
    
    // mixed date & date time period
    if let start = self.dateStart, let end = self.dateTimeEnd {
      // todo: I need to change start-time to 8:00
      return .init(dates: (start, end))
    }
    
    // some error occured
    return nil
  }
}

private func applyTimeZoneOffset(_ timeZone: TimeZone) -> (Absence.Period) -> Absence.Period? {
  return { period in
    return zip(with: { Absence.Period(startedAt: $0, finishedAt: $1) })(
      period.startedAt.dateByReplacingTimeZone(timeZone: timeZone),
      period.finishedAt.dateByReplacingTimeZone(timeZone: timeZone)
    )
  }
}

extension Webhook {
  internal var followupContext: Context? {
    return self.outputContexts
      .first { ContextName(rawValue: $0.name)?.identifier == .followup }
  }

  internal var fullContext: Context? {
    return self.outputContexts
      .first { ContextName(rawValue: $0.name)?.identifier == .full }
  }

  internal func fullContext(lifespanCount: Int, params: Context.Parameters) -> Context {
    return .init(
      name: ContextName(session: self.session, identifier: .full)!.rawValue,
      lifespanCount: lifespanCount,
      parameters: params
    )
  }

  internal func followupContext(lifespanCount: Int, params: Context.Parameters) -> Context {
    return .init(
      name: ContextName(session: self.session, identifier: .followup)!.rawValue,
      lifespanCount: lifespanCount,
      parameters: params
    )
  }
}

public struct ContextName: RawRepresentable, Equatable {
  public enum Identifier: String {
    case followup = "absenceday-followup"
    case full = "absenceday-full"
    case report = "absence-report-followup"
  }
  
  public private(set) var rawValue: String
  public init?(rawValue: String) {
    self.rawValue = rawValue
  }
  
  public var identifier: Identifier? {
    return URL(string: rawValue)
      .flatMap { Identifier(rawValue: $0.lastPathComponent) }
  }
  
  public init?(session: String, identifier: Identifier) {
    guard let rawValue = URL(string: session)?
      .appendingPathComponent("contexts")
      .appendingPathComponent(identifier.rawValue)
      .absoluteString else { return nil }
    
    self.rawValue = rawValue
  }
}
