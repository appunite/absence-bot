import Either
import Foundation
import Prelude
import Optics

public struct Absence: Codable, Equatable {
  public var requester: Either<Slack.User.Id, Slack.User>
  public var interval: DateInterval
  public var reason: Reason
  
  public var status: Status
  public var reviewer: Either<Slack.User.Id, Slack.User>?
  public var event: GoogleCalendar.Event?

  public enum Status: Int, Codable, Equatable {
    case pending
    case approved
    case rejected
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
  public static func pending(requester: Slack.User, interval: DateInterval, reason: Absence.Reason) -> Absence {
    return .init(requester: .right(requester), interval: interval, reason: reason, status: .pending, reviewer: nil, event: nil)
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

internal func calendarEvent(from absence: Absence) -> GoogleCalendar.Event {
  return .init(
    id: nil,
    colorId: absence.reason.colorId,
    htmlLink: nil,
    created: nil,
    updated: nil,
    summary: "\(absence.requester.right!.profile.name) - \(absence.reason.rawValue) \(absence.reason.emojis.randomElement()!)",
    description: nil,
    start: startDateTime(from: absence.interval),
    end: endDateTime(from: absence.interval),
    attendees: [
      .init(email: absence.requester.right!.profile.email, displayName: absence.requester.right!.profile.name),
      .init(email: absence.reviewer!.right!.profile.email, displayName: absence.reviewer!.right!.profile.name)
    ]
  )
}

private func startDateTime(from interval: DateInterval) -> GoogleCalendar.Event.DateTime {
  return .init(
    date: interval.isAllDay ? interval.start : nil,
    dateTime: !interval.isAllDay ? interval.end : nil
  )
}

private func endDateTime(from interval: DateInterval) -> GoogleCalendar.Event.DateTime {
  return .init(
    date: interval.isAllDay ? interval.start : nil,
    dateTime: !interval.isAllDay ? interval.end : nil
  )
}

extension Absence {
  public var announcementMessageText: String {
    // get absence date range string
    let interval = self.interval.dateRange(tz: Current.hqTimeZone())

    // generate text
    switch self.reason {
    case .illness:
      return "<@\(self.requesterId)> _is not feeling good_ and is asking for vacant \(interval) \(self.reason.emojis.first!)."
    case .holiday:
      return "<@\(self.requesterId)> will be unavailable because of _holidays_ planned \(interval) \(self.reason.emojis.first!)."
    case .remote:
      return "<@\(self.requesterId)> would love to _work from home_: \(interval) \(self.reason.emojis.first!)."
    case .conference:
      return "<@\(self.requesterId)> will participate in _conference_: \(interval) \(self.reason.emojis.first!)."
    case .school:
      return "<@\(self.requesterId)> will be less available because of _school_ duties: \(interval) \(self.reason.emojis.first!)."
    }
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

  public var emojis: [String] {
    switch self {
    case .illness:
      return ["🤒", "🤕", "🤧", "😷", "🤮"]
    case .holiday:
      return ["🏖", "🏄‍♂️", "🌴", "🍹", "⛱"]
    case .remote:
      return ["🏡", "👻", "👨‍💻", "👀"]
    case .conference:
      return ["👨‍🔬", "👨‍🏫", "🧠", "✍️"]
    case .school:
      return ["🦉", "🎓", "😱", "🤯"]
    }
  }
}
