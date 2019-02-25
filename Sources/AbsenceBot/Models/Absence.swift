import Either
import Foundation
import Prelude
import Optics

public struct Absence: Codable, Equatable {
  /// Keeps information about request status
  public var status: Status

  /// Defines who is requesting for absence
  public var requester: Either<Slack.User.Id, Slack.User>
  
  /// Defines when absence is requested
  public var interval: DateInterval
  
  /// Defines why requester is requesting for an absence
  public var reason: Reason
  
  /// Defines bot channel, used to information where respond about status change
  public var channel: Slack.Message.Channel
  
  /// Defines user Slack identifier or object of user who make a decition
  public var reviewer: Either<Slack.User.Id, Slack.User>?

  /// Defines Google Calendar Event object if request is approved
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
  public static func pending(requester: Slack.User, interval: DateInterval, reason: Absence.Reason, channel: Slack.Message.Channel) -> Absence {
    return .init(status: .pending, requester: .right(requester), interval: interval, reason: reason, channel: channel, reviewer: nil, event: nil)
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
    dateTime: !interval.isAllDay ? interval.start : nil
  )
}

private func endDateTime(from interval: DateInterval) -> GoogleCalendar.Event.DateTime {
  // if we're adding all day event, google is exluding end date, so we need to extend by one day
  let calendar = Calendar.gmtTimeZoneCalendar
  let nextDay = { date in
    return calendar.date(byAdding: .day, value: 1, to: date)
  }

  return .init(
    date: interval.isAllDay ? nextDay(interval.end) : nil,
    dateTime: !interval.isAllDay ? interval.end : nil
  )
}

extension Absence {
  public var announcementMessageText: String {
    // generate text
    switch self.reason {
    case .illness:
      return "<@\(self.requesterId)> _is not feeling good_ and is asking for vacant."
    case .holiday:
      return "<@\(self.requesterId)> will be unavailable because of _holidays_ planned"
    case .remote:
      return "<@\(self.requesterId)> would love to _work from home_"
    case .conference:
      return "<@\(self.requesterId)> will participate in _conference_"
    case .school:
      return "<@\(self.requesterId)> will be less available because of _school_ duties"
    }
  }
}

extension Absence.Reason {
  public var colorId: String {
    switch self {
    case .illness:
      return "2"
    case .holiday:
      return "7"
    case .remote:
      return "5"
    case .conference:
      return "0"
    case .school:
      return "9"
    }
  }

  public var colorHex: String {
    switch self {
    case .illness:
      return "#5db27e"
    case .holiday:
      return "#439bdf"
    case .remote:
      return "#eebf4b"
    case .conference:
      return "#966dab"
    case .school:
      return "#4154af"
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
      return ["🦉", "🎓", "😱", "🤯", "🤦‍♂️"]
    }
  }
}
