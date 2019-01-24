import Either
import Foundation
import Optics
import Prelude
import UrlFormEncoding
import SwiftJWT

public struct GoogleCalendar {
  /// Fetches Google OAuth access token
  public var fetchAuthToken: () -> EitherIO<Error, Either<OAuthError, AccessToken>>

  /// Create
  public var createEvent: (AccessToken, Event) -> EitherIO<Error, Event>

  static let live = GoogleCalendar(
    fetchAuthToken: { AbsenceBot.fetchAuthToken() |> runCalendar} ,
    createEvent: { AbsenceBot.createEvent(with: $0, event: $1) |> runCalendar }
  )

  public struct AccessToken: Codable {
    public private(set) var accessToken: String
    public private(set) var expiresIn: Int
    public private(set) var tokenType: String
    
    private enum CodingKeys: String, CodingKey {
      case accessToken = "access_token"
      case expiresIn = "expires_in"
      case tokenType = "token_type"
    }
  }
  
  public struct OAuthError: Codable {
    public private(set) var description: String
    public private(set) var error: Error
    
    public enum Error: String, Codable {
      case invalidGrant = "invalid_grant"
    }
    
    private enum CodingKeys: String, CodingKey {
      case description = "error_description"
      case error
    }
  }

  // docs: https://developers.google.com/calendar/v3/reference/events/insert
  public struct Event: Codable {
    public private(set) var id: String?
    public private(set) var colorId: Int?
    public private(set) var htmlLink: URL?
    public private(set) var created: Date?
    public private(set) var updated: Date?
    public private(set) var summary: String
    public private(set) var description: String
    public private(set) var attendees: [Actor]
    public private(set) var start: DateTime
    public private(set) var end: DateTime

    public struct Actor: Codable {
      public var email: String
      public var displayName: String
    }

    public struct DateTime: Codable {
      public var date: Date?
      public var dateTime: Date?
    }
  }
}

func fetchAuthToken() -> DecodableRequest<Either<GoogleCalendar.OAuthError, GoogleCalendar.AccessToken>> {
  var jwt = defaultOAuthPayload(Current.date())
  let jwtString = try! jwt.sign(using: rs256Signer!)

  let bodyParts = [
    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion": jwtString
  ]

  return DecodableRequest(
    rawValue: URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v4/token")!)
      |> \.httpMethod .~ "POST"
      |> \.httpBody .~ Data(urlFormEncode(value: bodyParts).utf8)
      |> \.allHTTPHeaderFields .~ [
        "Content-type": "application/x-www-form-urlencoded"
    ]
  )
}

func createEvent(with token: GoogleCalendar.AccessToken, event: GoogleCalendar.Event) -> DecodableRequest<GoogleCalendar.Event> {
  let body = try? calendarJsonEncoder
    .encode(event)
  
  return DecodableRequest(
    rawValue: URLRequest(url: URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(Current.envVars.google.calendar)/events")!)
      |> \.httpMethod .~ "POST"
      |> \.httpBody .~ body
      |> \.allHTTPHeaderFields .~ [
        "Authorization": "Bearer \(token.accessToken)",
        "Content-type": "application/json"
    ]
  )
}

private func runCalendar<A>(_ gitHubRequest: DecodableRequest<A>) -> EitherIO<Error, A> {
  return jsonDataTask(with: gitHubRequest.rawValue, decoder: calendarJsonDecoder)
}

public struct OAuthPayload {
  public private(set) var iss: String
  public private(set) var scope: String
  public private(set) var aud: String
  public private(set) var iat: Date?
  public private(set) var exp: Date?
}

extension OAuthPayload: Claims {}

private let defaultOAuthPayload: (Date) -> JWT<OAuthPayload> = { date in
  let payload =  OAuthPayload(iss: Current.envVars.google.clientEmail,
                      scope: "https://www.googleapis.com/auth/calendar.events",
                      aud: "https://www.googleapis.com/oauth2/v4/token",
                      iat: date,
                      exp: date.addingTimeInterval(3600)
  )

  return JWT<OAuthPayload>.init(claims: payload)
}

private let rs256Signer = Current.envVars.google.privteKey
  .data(using: .utf8)
  .map(JWTSigner.rs256(privateKey:))

private let calendarJsonDecoder = JSONDecoder()
  |> \.dateDecodingStrategy .~ .secondsSince1970
private let calendarJsonEncoder = JSONEncoder()
  |> \.dateEncodingStrategy .~ .secondsSince1970
