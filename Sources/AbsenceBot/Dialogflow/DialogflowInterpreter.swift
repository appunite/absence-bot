import Foundation
import HttpPipeline
import Prelude
import Optics
import Tuple

public func interprete(payload: Webhook, user: Slack.User) -> Status {
  guard let action = Webhook.Action(rawValue: payload.action)
    else { fatalError("Undefined action type!") }

  switch action {
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
  internal enum Action: String {
    case full = "absenceday.absenceday-full"
    case fillDate = "absenceday.absenceday-fill-date"
    case accept = "absenceday.absenceday-yes"
  }
}

extension Webhook {
  private enum ContextIdentifier: String {
    case followup = "absenceday-followup"
    case full = "absenceday-full"
    case report = "absence-report-followup"
  }

  internal var followupContext: Context? {
    return self.outputContexts
      .first { $0.name.lastPathComponent == ContextIdentifier.followup.rawValue }
  }

  internal var fullContext: Context? {
    return self.outputContexts
      .first { $0.name.lastPathComponent == ContextIdentifier.full.rawValue }
  }

  internal func fullContext(lifespanCount: Int, params: Context.Parameters) -> Context {
    return context(with: .full, lifespanCount: lifespanCount, params: params)
  }

  internal func followupContext(lifespanCount: Int, params: Context.Parameters) -> Context {
    return context(with: .followup, lifespanCount: lifespanCount, params: params)
  }

  private func context(with identifier: ContextIdentifier, lifespanCount: Int, params: Context.Parameters) -> Context {
    let name = URL(string: self.session)!
      .appendingPathComponent("contexts")
      .appendingPathComponent(identifier.rawValue)

    return .init(
      name: name,
      lifespanCount: lifespanCount,
      parameters: params
    )
  }
}

