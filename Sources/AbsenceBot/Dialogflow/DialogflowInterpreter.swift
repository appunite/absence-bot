import Foundation
import Prelude
import Optics

public func interprete(payload: Dialogflow, timeZone: TimeZone) -> Status {
  switch payload.action {    
  case .full, .fillDate:
    let followupContextParams = payload.outputContexts
      .first { $0.name.identifier == .followup }
      .map { $0.parameters }
    
    guard let reason = followupContextParams?.reason
      else { return .incomplete(Fulfillment(text: .raw("There is no reason value."))) }
    
    // we don't have any dates, we need to ask about them
    guard let period = followupContextParams
      .flatMap (period(with:))
      .flatMap ({ $0.applyTimeZoneOffsetFix(timeZone: timeZone) })
      else { return .incomplete(Fulfillment(text: .missingPeriod)) }
    
    // create full context
    let fullContext = zip(with: { Context( name: $0, lifespanCount: 2, parameters: $1) })(
      ContextName(session: payload.session, identifier: .full), followupContextParams)
    
    // we have all date, let's ask user if everytking is ok
    return .incomplete(Fulfillment(text: .confirmation(reason, period, timeZone), contexts: [fullContext].compactMap {$0} ))
    
  case .accept:
    let followupContextParams = payload.outputContexts
      .first { $0.name.identifier == .followup }
      .map { $0.parameters }
    
    guard let reason = followupContextParams?.reason
      else { return .incomplete(Fulfillment(text: .raw("There is no reason value."))) }
    
    guard let period = followupContextParams
      .flatMap (period(with:))
      .flatMap ({ $0.applyTimeZoneOffsetFix(timeZone: timeZone) })
      else { return .incomplete(Fulfillment(text: .raw("There is no date defined."))) }
    
    // create full context with clear-out lifespan count
    let _fullContext = zip(with: { Context( name: $0, lifespanCount: 0, parameters: $1) })(
      ContextName(session: payload.session, identifier: .full), .init())
    
    // create followup context with clear-out lifespan count
    let _followupContext = zip(with: { Context( name: $0, lifespanCount: 0, parameters: $1) })(
      ContextName(session: payload.session, identifier: .followup), .init())
    
    // we're done, send tanks comment and clear out contextes
    return .complete(reason, period, Fulfillment(text: .thanks, contexts: [
      _fullContext, _followupContext].compactMap { $0 }))
  }
}

private func period(with parameters: Context.Parameters) -> Period? {
  // single day absence
  if let date = parameters.date {
    // if there is no information about time, just treat this as full day
    guard let timeStart = parameters.timeStart, let timeEnd = parameters.timeEnd
      else { return Period(dates: (date, date)) }
    
    // extend day with time information
    return zip(with: { Period(dates: ($0, $1)) })(
      date.dateByReplacingTime(from: timeStart),
      date.dateByReplacingTime(from: timeEnd)
    )
  }
  
  // date time period
  if let start = parameters.dateTimeStart, let end = parameters.dateTimeEnd {
    return Period(dates: (start, end))
  }
  
  // period absence
  if let period = parameters.datePeriod {
    return Period(dates: (period.startDate, period.endDate))
  }
  
  // date period
  if let start = parameters.dateStart, let end = parameters.dateEnd {
    return Period(dates: (start, end))
  }
  
  // mixed date & date time period
  if let start = parameters.dateTimeStart, let end = parameters.dateEnd {
    // todo: I need to change end-time to 17:00
    return Period(dates: (start, end))
  }
  
  // mixed date & date time period
  if let start = parameters.dateStart, let end = parameters.dateTimeEnd {
    // todo: I need to change start-time to 8:00
    return Period(dates: (start, end))
  }
  
  // some error occured
  return nil
}

