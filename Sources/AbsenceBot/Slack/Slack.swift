import Either
import Foundation
import Optics
import Prelude
import UrlFormEncoding

public struct Slack {
  /// Fetches a Slack user profile by id.
  public var fetchUser: (String) -> EitherIO<Error, Either<SlackError, UserPayload>>

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
    public private(set) var id: String
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
      public private(set) var team: String

      private enum CodingKeys: String, CodingKey {
        case name = "real_name"
        case email
        case team
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
    public private(set) var text: String
    public private(set) var channel: String
    public private(set) var attachments: [Attachment]
    
    public struct Attachment: Codable {
      public private(set) var text: String
      public private(set) var fallback: String?
      public private(set) var callbackId: String?
      public private(set) var actions: [InteractiveAction]?

      enum CodingKeys: String, CodingKey {
        case text
        case fallback
        case callbackId = "callback_id"
        case actions
      }
      
      public struct InteractiveAction: Codable, Equatable {
        public private(set) var name: String
        public private(set) var text: String?
        public private(set) var type: String
        public private(set) var value: Action
        
        public enum Action: String, Codable {
          case accept
          case reject
        }
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
    self.id = try container.decode(String.self, forKey: .id)
    self.profile = try container.decode(Profile.self, forKey: .profile)

    // parse time-zone
    let timezoneOffset = try container.decode(Int.self, forKey: .tz)
    self.tz = TimeZone(secondsFromGMT: timezoneOffset)!
  }
}

func fetchUser(with id: String) -> DecodableRequest<Either<Slack.SlackError, Slack.UserPayload>> {
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

private let slackJsonDecoder = JSONDecoder()
  |> \.dateDecodingStrategy .~ .secondsSince1970
private let slackJsonEncoder = JSONEncoder()
  |> \.dateEncodingStrategy .~ .secondsSince1970

import MessagePack
extension Slack.Message {
  public static func announcementMessage(absence: Absence) -> Slack.Message {
    // generate attachement
    let attachment = Slack.Message.Attachment(
      text: "Let me know what you think about this.",
      fallback: "Absence acceptance interactive message",
      callbackId: try! MessagePackEncoder().encode(absence).base64EncodedString(),
      actions: [
        .init(name: "accept", text: "Accept 👍", type: "button", value: .accept),
        .init(name: "reject", text: "Reject 👎", type: "button", value: .reject)]
    )

    // get absence date range string
    let period = absence.period.dateRange(tz: Current.hqTimeZone())

    // generate text // get2(conn.data)!.name
    let text = "<@\(absence.user.id)> is asking for vacant \(period) because of the \(absence.reason.rawValue)."
    
    // generate message
    return Slack.Message(text: text, channel: Current.envVars.slack.channel, attachments: [attachment])
  }
  
  static func rejectionNotificationMessage(requester: String) -> Slack.Message {
    return Slack.Message(text: "Bad news! Your absence request was rejected", channel: requester, attachments: [])
  }

}
