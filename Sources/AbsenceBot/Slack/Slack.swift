import Either
import Foundation
import Optics
import Prelude
import UrlFormEncoding
import HttpPipeline

public struct Slack {
  /// Fetches a Slack user profile by id.
  public var fetchUser: (Slack.User.Id) -> EitherIO<Error, Either<SlackError, UserPayload>>

  /// Post message on channel
  public var uploadFile: (File) -> EitherIO<Error, Either<SlackError, StatusPayload>>

  /// Post message on channel
  public var postMessage: (Message) -> EitherIO<Error, Either<SlackError, StatusPayload>>

  static let live = Slack(
    fetchUser: AbsenceBot.fetchUser >>> runSlack,
    uploadFile: AbsenceBot.uplaodFile >>> runSlack,
    postMessage: AbsenceBot.postMessage >>> runSlack
  )

  public struct UserPayload: Codable, Equatable  {
    public private(set) var user: User
  }
  
  public struct User: Codable, Equatable {
    public typealias Id = Tagged<User, String>
    public private(set) var id: Id
    
    public private(set) var profile: Profile
    public private(set) var tz: TimeZone


    private enum CodingKeys: String, CodingKey {
      case id
      case profile
      case tz = "tz_offset"
    }

    public struct Profile: Codable, Equatable {
      public private(set) var name: String
      public private(set) var email: String

      private enum CodingKeys: String, CodingKey {
        case name = "real_name"
        case email
      }
    }
  }

  public struct StatusPayload: Codable {
    public private(set) var ok: Bool
  }
  
  public struct File: Encodable {
    public private(set) var content: String
    public private(set) var channels: String
    public private(set) var filename: String
    public private(set) var filetype: String
    public private(set) var title: String
  }

  public struct Message: Codable {
    public typealias Channel = Tagged<Message, String>

    public private(set) var text: String?
    public private(set) var channel: Channel
    public private(set) var attachments: [Attachment]
    
    public struct Attachment: Codable {
      public private(set) var title: String?
      public private(set) var text: String?
      public private(set) var footer: String?
      public private(set) var ts: Date?
      public private(set) var color: String?
      public private(set) var fallback: String?
      public private(set) var callbackId: String?
      public private(set) var fields: [Field]?
      public private(set) var actions: [InteractiveAction]?

      enum CodingKeys: String, CodingKey {
        case title
        case text
        case fallback
        case callbackId = "callback_id"
        case actions
        case color
        case footer
        case ts
        case fields
      }
      
      public struct InteractiveAction: Codable, Equatable {
        public private(set) var name: String
        public private(set) var type: String
        public private(set) var style: String?
        public private(set) var text: String?
        public private(set) var value: Action
        
        public enum Action: String, Codable {
          case accept
          case reject
        }
        
        public var isAccepted: Bool {
          if case .accept = value {
            return true
          }
          return false
        }
        
        public var isRejected: Bool {
          return !isAccepted
        }
      }

      public struct Field: Codable {
        public private(set) var title: String?
        public private(set) var value: String?
        public private(set) var short: Bool?
      }
    }
  }

  public struct SlackError: Error, Codable {
    public private(set) var error: String
  }
}

extension Slack.File {
  public init(content: Data, channels: String, filename: String, filetype: String, title: String) {
    self.content = String(data: content, encoding: .utf8)!
    self.channels = channels
    self.filename = filename
    self.filetype = filetype
    self.title = title
  }
}

extension Slack.User {
  public func encode(to encoder: Encoder) throws {
    var container = encoder
      .container(keyedBy: CodingKeys.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.tz.secondsFromGMT(), forKey: .tz)
    try container.encode(self.profile, forKey: .profile)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder
      .container(keyedBy: CodingKeys.self)

    // user basic info
    self.id = try container.decode(Slack.User.Id.self, forKey: .id)
    self.profile = try container.decode(Profile.self, forKey: .profile)

    // parse time-zone
    let timezoneOffset = try container.decode(Int.self, forKey: .tz)
    self.tz = TimeZone(secondsFromGMT: timezoneOffset)!
  }
}

func fetchUser(with id: Slack.User.Id) -> DecodableRequest<Either<Slack.SlackError, Slack.UserPayload>> {
  return DecodableRequest(
    rawValue: URLRequest(url: URL(string: "https://slack.com/api/users.info?user=\(id)")!)
      |> \.httpMethod .~ "GET"
      |> \.allHTTPHeaderFields .~ [
        "Authorization": "Bearer \(Current.envVars.slack.token)"
    ]
  )
}

func uplaodFile(with file: Slack.File) -> DecodableRequest<Either<Slack.SlackError, Slack.StatusPayload>> {
  return DecodableRequest(
    rawValue: URLRequest(url: URL(string: "https://slack.com/api/files.upload")!)
      |> \.httpMethod .~ "POST"
      |> \.httpBody .~ Data(urlFormEncode(value: file).utf8)
      |> \.allHTTPHeaderFields .~ [
        "Authorization": "Bearer \(Current.envVars.slack.token)",
        "Content-type": "application/x-www-form-urlencoded"
    ]
  )
}

func postMessage(with message: Slack.Message) -> DecodableRequest<Either<Slack.SlackError, Slack.StatusPayload>> {
  let body = try? slackJsonEncoder
    .encode(message)

  return DecodableRequest(
    rawValue: URLRequest(url: URL(string: "https://slack.com/api/chat.postMessage")!)
      |> \.httpMethod .~ "POST"
      |> \.httpBody .~ body
      |> \.allHTTPHeaderFields .~ [
        "Authorization": "Bearer \(Current.envVars.slack.token)",
        "Content-type": "application/json"
    ]
  )
}

private func runSlack<A>(_ gitHubRequest: DecodableRequest<A>) -> EitherIO<Error, A> {
  return jsonDataTask(with: gitHubRequest.rawValue, decoder: slackJsonDecoder)
}

public let slackJsonDecoder = JSONDecoder()
  |> \.dateDecodingStrategy .~ .secondsSince1970
public let slackJsonEncoder = JSONEncoder()
  |> \.dateEncodingStrategy .~ .secondsSince1970

extension Slack.Message.Attachment {
  public static func text(text: String?) -> Slack.Message.Attachment {
    return .init(title: nil, text: text, footer: nil, ts: Current.date(), color: nil, fallback: nil, callbackId: nil, fields: nil, actions: nil)
  }

  public static func acceptanceAttachement(absence: Absence) -> Slack.Message.Attachment {
    return .text(text: "\(absence.reviewerId.map { "<@\($0)>" } ?? "@unknown") approved this request.\(absence.event?.htmlLink.map { " Calendar event is <\($0.absoluteString)|here>" } ?? "").")
  }

  public static func rejectionAttachement(absence: Absence) -> Slack.Message.Attachment {
    return .text(text: "\(absence.reviewerId.map { "<@\($0)>" } ?? "@unknown") rejected this request.")
  }

  public static func approvalRequestAttachement(absence: Absence, callback: String?, actions: [InteractiveAction]?) -> Slack.Message.Attachment {
    return .init(title: "Approval Request", text: "Your approval is requested here. \(absence.announcementMessageText)", footer: nil, ts: nil, color: absence.reason.colorHex, fallback: "Absence acceptance interactive message", callbackId: callback, fields: [.reason(absence), .interval(absence)], actions: actions)
  }

  public static func announcementAttachment(absence: Absence) -> Slack.Message.Attachment {
    let rawAbsence = absence
      |> \.requester .~ .left(absence.requesterId)
    
    let payload = try! JSONEncoder()
      .encode(rawAbsence)
      .base64EncodedString()

    return .approvalRequestAttachement(absence: absence, callback: payload, actions: [.accept(), .reject()])
  }
}

extension Slack.Message.Attachment.InteractiveAction {
  public static func accept() -> Slack.Message.Attachment.InteractiveAction {
    return .init(name: "accept", type: "button", style: "primary", text: "Approve", value: .accept)
  }
  
  public static func reject() -> Slack.Message.Attachment.InteractiveAction {
    return .init(name: "reject", type: "button", style: "danger", text: "Reject", value: .reject)
  }
}

extension Slack.Message.Attachment.Field {
  public static func reason(_ absence: Absence) -> Slack.Message.Attachment.Field {
    return .init(title: "Reason", value: "\(absence.reason.rawValue) \(absence.reason.emojis.first!)", short: true)
  }
  
  public static func interval(_ absence: Absence) -> Slack.Message.Attachment.Field {
    return .init(title: "Interval", value: absence.interval.dateRange(tz: Current.hqTimeZone(), bolded: false), short: true)
  }
}

extension Slack.Message {
  public static func announcementMessage(absence: Absence) -> Slack.Message {
    // generate message
    return .init(
      text: nil,
      channel: .init(rawValue: Current.envVars.slack.channel),
      attachments: [.announcementAttachment(absence: absence)])
  }
  
  public static func rejectionNotificationMessage(absence: Absence) -> Slack.Message {
    return Slack.Message(text: "Bad news! Your absence request was rejected", channel: absence.channel, attachments: [])
  }
  
  public static func acceptanceNotificationMessage(absence: Absence) -> Slack.Message {
    // create generic message
    let message = Slack.Message(text: "Good news! Your absence request was approved. I've already created the \(absence.event?.htmlLink.map {"<\($0.absoluteString)|event>"} ?? "event") in absence calendar", channel: absence.channel, attachments: [])

    // extend message with attachment if illnes
    switch absence.reason {
    case .illness:
      return message
        |> \.attachments .~ [.text(text: "*Only related to employment contracts.* Your employer’s details you should get your sick note with are:\n ```\(imgeCompanyAddress)```")]
    default:
      return message
    }
  }
}

private let imgeCompanyAddress = """
IMGE sp. z o.o.
ul. Droga Dębińska 3a/3
61-555 Poznań
NIP 783-172-43-36
"""

public func slackComputedDigest(key: String, body: Data?, timestamp: String) -> String? {
  let value = "v0:\(timestamp):\(body.flatMap { String(data: $0, encoding: .utf8) } ?? "")"
  return hexDigest(value: value, asciiSecret: key)
    .flatMap {"v0=\($0)"}
}
