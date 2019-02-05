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

  public struct UserPayload: Codable {
    public private(set) var user: User
  }
  
  public struct User {
    public private(set) var id: String
    public private(set) var team: String
    public private(set) var name: String
    public private(set) var email: String
    public private(set) var timezone: TimeZone
    
    private enum CustomCodingKeys: String, CodingKey {
      case id
      case name = "real_name"
      case profile
      case timezone = "tz_offset"
    }
    
    private enum ProfileCodingKeys: String, CodingKey {
      case team
      case email
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
      public private(set) var fallback: String?
      public private(set) var text: String
      public private(set) var callbackId: String?
      public private(set) var actions: [InteractiveAction]?

      enum CodingKeys: String, CodingKey {
        case fallback
        case text
        case callbackId = "callback_id"
        case actions
      }
      
      public struct InteractiveAction: Codable {
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

extension Slack.User: Encodable {}
extension Slack.User: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CustomCodingKeys.self)
    
    // user basic info
    self.id = try container.decode(String.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    
    // parse time-zone
    let timezoneOffset = try container.decode(Int.self, forKey: .timezone)
    self.timezone = TimeZone(secondsFromGMT: timezoneOffset)!
    
    // email
    let profile = try container.nestedContainer(keyedBy: ProfileCodingKeys.self, forKey: .profile)
    self.team = try profile.decode(String.self, forKey: .team)
    self.email = try profile.decode(String.self, forKey: .email)
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


extension Slack.Message {
  public static func announcementMessage(absence: Absence)  -> Slack.Message {
    // generate attachement
    let attachment = Slack.Message.Attachment(
      fallback: "Absence acceptance interactive message",
      text: "Let me know what you think about this.",
      callbackId: "id", //todo
      actions: [
        .init(name: "accept", text: "Accept 👍", type: "button", value: .accept),
        .init(name: "reject", text: "Reject 👎", type: "button", value: .reject)]
    )

    // get absence date range string
    let period = absence.period
      .dates(timeZone: Current.hqTimeZone())
      .map({ "*\($0)*" })
      .joined(separator: " - ")

    // generate text // get2(conn.data)!.name
    let text = "<@\(absence.user.id)> is asking for vacant \(period) because of the \(absence.reason.rawValue)."
    
    // generate message
    return Slack.Message(text: text, channel: Current.envVars.slack.channel, attachments: [attachment])
  }
}
