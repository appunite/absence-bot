import Either
import Foundation
import HttpPipeline
import Prelude
import Optics
import UrlFormEncoding

public struct Absence: Codable, Equatable {
  public var requester: Either<Slack.User.Id, Slack.User>
  public var period: Period
  public var reason: Reason
  public var reviewer: Slack.User?
  
  public struct Period: Codable, Equatable {
    public var startedAt: Date
    public var finishedAt: Date
  }

  public enum Reason: String, Codable, RawRepresentable, Equatable {
    case illness
    case holiday
    case remote
    case conference
    case school
  }
}

extension Absence {
  public var requesterId: Slack.User.Id {
    switch requester {
    case .left(let id):
      return id
    case .right(let user):
      return user.id
    }
  }
}

extension Absence.Period {
  public init(dates: (Date, Date), tz: TimeZone?) {
    let sortedDates = [dates.0, dates.1]
      .sorted(by: <)

    self.startedAt = tz.flatMap { sortedDates.first!.dateByReplacingTimeZone(timeZone: $0) } ?? sortedDates.first!
    self.finishedAt = tz.flatMap { sortedDates.last!.dateByReplacingTimeZone(timeZone: $0) } ?? sortedDates.last!
  }

  public var isAllDay: Bool {
    let dateComponentsA = Calendar.gmtTimeZoneCalendar
      .dateComponents([.hour, .minute, .second], from: startedAt)
    let dateComponentsB = Calendar.gmtTimeZoneCalendar
      .dateComponents([.hour, .minute, .second], from: finishedAt)
    
    return dateComponentsA == dateComponentsB
  }
}

extension Absence.Period {
  static let daysRangeFormatter: (TimeZone) -> DateFormatter = { timeZone in
    return DateFormatter()
      |> \.locale .~ Locale(identifier: "en_US_POSIX")
      |> \.timeZone .~ timeZone
      |> \.dateStyle .~ .long
      |> \.timeStyle .~ .none
  }
  
  static let dateTimeRangeFormatter: (TimeZone) -> DateFormatter = { timeZone in
    return DateFormatter()
      |> \.locale .~ Locale(identifier: "en_US_POSIX")
      |> \.timeZone .~ timeZone
      |> \.dateStyle .~ .long
      |> \.timeStyle .~ .short
  }
  
  func dates(tz: TimeZone) -> [String] {
    let sortedDates = Array(Set([self.startedAt, self.finishedAt]))
      .sorted(by: <)
    
    if self.isAllDay {
      return sortedDates
        .compactMap { Absence.Period.daysRangeFormatter(tz).string(from: $0) }
    } else {
      return sortedDates
        .compactMap { Absence.Period.dateTimeRangeFormatter(tz).string(from: $0) }
    }
  }

  func dateRange(tz: TimeZone) -> String {
    return dates(tz: tz)
      .map({"*\($0)*"})
      .joined(separator: " - ")
  }
}