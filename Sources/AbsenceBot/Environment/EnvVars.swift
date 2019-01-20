import Foundation

public struct EnvVars: Codable {
  public var appEnv = AppEnv.development
  public var baseUrl = URL(string: "http://localhost:8080")!
  public var port = 8080
  public var google = Google()
  public var slack = Slack()
  public var postgres = Postgres()

  private enum CodingKeys: String, CodingKey {
    case appEnv = "APP_ENV"
    case baseUrl = "BASE_URL"
    case port = "PORT"
  }

  public enum AppEnv: String, Codable {
    case development
    case production
    case staging
    case testing
  }

  public struct Slack: Codable {
    public var channel = "#random"
    public var token = "xoxb-1115164490-464545011382-76zUKi9AzSM2GG7RfAXvVHfW"
    
    private enum CodingKeys: String, CodingKey {
      case channel = "SLACK_ANNOUNCEMENT_CHANNEL"
      case token = "SLACK_AUTH_TOKEN"
    }
  }
  
  public struct Postgres: Codable {
    public var databaseUrl = "postgres://postgres:@localhost:5432/postgres"
    
    private enum CodingKeys: String, CodingKey {
      case databaseUrl = "DATABASE_URL"
    }
  }

  public struct Google: Codable {
    public var calendar = "appunite.com_bot@group.calendar.google.com"
    public var clientEmail = "absencebot-server@absencebot-360ba.iam.gserviceaccount.com"
    public var clientId = "108750301185230262303"
    public var appName = "absencebot"
    public var privteKey = "-----BEGIN PRIVATE KEY-----\nnMIIEvgbFpvf\n-----END PRIVATE KEY-----\n"
    private enum CodingKeys: String, CodingKey {
      case calendar = "GOOGLE_CALENDAR_ID"
      case clientEmail = "GOOGLE_CLIENT_EMAIL"
      case clientId = "GOOGLE_CLIENT_ID"
      case appName = "GOOGLE_APP_NAME"
      case privteKey = "GOOGLE_PRIVATE_KEY"
    }
  }
}

extension EnvVars {
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    self.appEnv = try values.decode(AppEnv.self, forKey: .appEnv)
    self.baseUrl = try values.decode(URL.self, forKey: .baseUrl)
    self.port = Int(try values.decode(String.self, forKey: .port))!
    self.google = try .init(from: decoder)
    self.slack = try .init(from: decoder)
    self.postgres = try .init(from: decoder)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(self.appEnv, forKey: .appEnv)
    try container.encode(self.baseUrl, forKey: .baseUrl)
    try container.encode(String(self.port), forKey: .port)
    try self.google.encode(to: encoder)
    try self.slack.encode(to: encoder)
    try self.postgres.encode(to: encoder)
  }
}

extension EnvVars {
  public func assigningValuesFrom(_ env: [String: String]) -> EnvVars {
    let decoded = (try? encoder.encode(self))
      .flatMap { try? decoder.decode([String: String].self, from: $0) }
      ?? [:]

    let assigned = decoded.merging(env, uniquingKeysWith: { $1 })

    return (try? JSONSerialization.data(withJSONObject: assigned))
      .flatMap { try? decoder.decode(EnvVars.self, from: $0) }
      ?? self
  }
}

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()
