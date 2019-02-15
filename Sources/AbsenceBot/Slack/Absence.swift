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
  
  public var status: Status
  public var reviewer: Either<Slack.User.Id, Slack.User>?
  public var event: GoogleCalendar.Event?

  public enum Status: Int, Codable, Equatable {
    case pending
    case approved
    case rejected
  }

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
  public static func pending(requester: Slack.User, period: Absence.Period, reason: Absence.Reason) -> Absence {
    return .init(requester: .right(requester), period: period, reason: reason, status: .pending, reviewer: nil, event: nil)
  }
}

extension Absence {
  public var isAccepted: Bool {
    if case .approved = status {
      return true
    }
    return false
  }
  
  public var isRejected: Bool {
    if case .rejected = status {
      return true
    }
    return false
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

  public var reviewerId: Slack.User.Id? {
    switch reviewer {
    case .some(.left(let id)):
      return id
    case .some(.right(let user)):
      return user.id
    default:
      return nil
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

internal func calendarEvent(from absence: Absence) -> GoogleCalendar.Event {
  return .init(
    id: nil,
    colorId: absence.reason.colorId,
    htmlLink: nil,
    created: nil,
    updated: nil,
    summary: "\(absence.requester.right!.profile.name) - \(absence.reason.rawValue) \(absence.reason.emoji)",
    description: nil,
    start: startDateTime(from: absence.period),
    end: endDateTime(from: absence.period),
    attendees: [
      .init(email: absence.requester.right!.profile.email, displayName: absence.requester.right!.profile.name),
      .init(email: absence.reviewer!.right!.profile.email, displayName: absence.reviewer!.right!.profile.name)
    ]
  )
}

private func startDateTime(from period: Absence.Period) -> GoogleCalendar.Event.DateTime {
  return .init(
    date: period.isAllDay ? period.startedAt : nil,
    dateTime: !period.isAllDay ? period.startedAt : nil
  )
}

private func endDateTime(from period: Absence.Period) -> GoogleCalendar.Event.DateTime {
  return .init(
    date: period.isAllDay ? period.finishedAt : nil,
    dateTime: !period.isAllDay ? period.finishedAt : nil
  )
}

extension Absence {
  public var announcementMessageText: String {
    // get absence date range string
    let period = self.period.dateRange(tz: Current.hqTimeZone())

    // generate text
    return "<@\(self.requesterId)> is asking for vacant \(period) because of the \(self.reason.rawValue)."
  }
}

extension Absence.Reason {
  public var colorId: String {
    switch self {
    case .illness:
      return "11"
    case .holiday:
      return "10"
    case .remote:
      return "7"
    case .conference:
      return "3"
    case .school:
      return "5"
    }
  }

  public var emoji: String {
    switch self {
    case .illness:
      return ["🤕", "🤧","🤒", "😷", "🤮"].randomElement()!
    case .holiday:
      return ["🏄‍♂️", "🌴", "🍹", "🏖", "⛱"].randomElement()!
    case .remote:
      return ["👻", "👨‍💻", "🏡", "👀"].randomElement()!
    case .conference:
      return ["👨‍🔬", "👨‍🏫", "🧠", "✍️"].randomElement()!
    case .school:
      return ["🎓", "🦉", "😱", "🤯"].randomElement()!
    }
  }
}
