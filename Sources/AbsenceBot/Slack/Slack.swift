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
  public var postMessage: (String, String) -> EitherIO<Error, Either<SlackError, StatusPayload>>

  static let live = Slack(
    fetchUser: AbsenceBot.fetchUser >>> runSlack,
    uploadFile: AbsenceBot.uplaodFile >>> runSlack,
    postMessage: { AbsenceBot.postMessage(with: $0, channel: $1) |> runSlack }
  )

  public struct UserPayload: Decodable {
    public private(set) var user: User
  }
  
  public struct User {
    public private(set) var id: String
    public private(set) var team: String
    public private(set) var name: String
    public private(set) var email: String
    public private(set) var timezone: TimeZone
    
    private enum CodingKeys: String, CodingKey {
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

  public struct StatusPayload: Decodable {
    public private(set) var ok: Bool
  }
  
  public struct File: Encodable {
    public private(set) var content: String
    public private(set) var channels: String
    public private(set) var filename: String
    public private(set) var filetype: String
    public private(set) var title: String
  }

  public struct SlackError: Decodable {
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

extension Slack.User: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
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

func postMessage(with text: String, channel: String) -> DecodableRequest<Either<Slack.SlackError, Slack.StatusPayload>> {
  let body = try? slackJsonEncoder
    .encode(["text": text, "channel": channel])

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
