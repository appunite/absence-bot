import Foundation
import Optics
import Prelude

public struct Webhook: Equatable {
  public var session: URL
  public var user: Slack.User.Id
  public var channel: Slack.Message.Channel
  public var action: Action
  public var outputContexts: [Context]

  public enum Action: String, Codable {
    case full = "absenceday.absenceday-full"
    case fillDate = "absenceday.absenceday-fill-date"
    case accept = "absenceday.absenceday-yes"
  }

  private enum OriginalDetectIntentRequestCodingKeys: String, CodingKey {
    case payload
  }

  private enum SlackPayloadCodingKeys: String, CodingKey {
    case data
  }

  private enum SlackDataCodingKeys: String, CodingKey {
    case event
  }

  private enum SlackEventCodingKeys: String, CodingKey {
    case user
    case channel
  }

  private enum CustomCodingKeys: String, CodingKey {
    case session
    case queryResult
    case originalDetectIntentRequest
  }

  private enum QueryResultCodingKeys: String, CodingKey {
    case action
    case outputContexts
  }
}

extension Webhook: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CustomCodingKeys.self)

    // session indetifier
    self.session = try container.decode(URL.self, forKey: .session)

    // contextes
    let queryResult = try container.nestedContainer(keyedBy: QueryResultCodingKeys.self, forKey: .queryResult)
    self.action = try queryResult.decode(Action.self, forKey: .action)
    self.outputContexts = try queryResult
      .decodeIfPresent([Throwable<Context>].self, forKey: .outputContexts)?
      .compactMap ({ $0.value }) ?? []

    // slack data
    let originalDetectIntentRequest = try container
      .nestedContainer(keyedBy: Webhook.OriginalDetectIntentRequestCodingKeys.self, forKey: .originalDetectIntentRequest)
    let payload = try originalDetectIntentRequest
      .nestedContainer(keyedBy: Webhook.SlackPayloadCodingKeys.self, forKey: .payload)
    let data = try payload
      .nestedContainer(keyedBy: Webhook.SlackDataCodingKeys.self, forKey: .data)
    let event = try data
      .nestedContainer(keyedBy: Webhook.SlackEventCodingKeys.self, forKey: .event)
    self.user = try event.decode(Slack.User.Id.self, forKey: .user)
    self.channel = try event.decode(Slack.Message.Channel.self, forKey: .channel)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder
      .container(keyedBy: CustomCodingKeys.self)
    try container.encode(self.session, forKey: .session)

    // contextes
    var queryResult = container
      .nestedContainer(keyedBy: QueryResultCodingKeys.self, forKey: .queryResult)
    try queryResult.encode(self.action, forKey: .action)
    try queryResult.encodeIfPresent(self.outputContexts, forKey: .outputContexts)
    
    // slack data
    var originalDetectIntentRequest = container
      .nestedContainer(keyedBy: Webhook.OriginalDetectIntentRequestCodingKeys.self, forKey: .originalDetectIntentRequest)
    var payload = originalDetectIntentRequest
      .nestedContainer(keyedBy: Webhook.SlackPayloadCodingKeys.self, forKey: .payload)
    var data = payload
      .nestedContainer(keyedBy: Webhook.SlackDataCodingKeys.self, forKey: .data)
    var event = data
      .nestedContainer(keyedBy: Webhook.SlackEventCodingKeys.self, forKey: .event)
    try event.encode(self.user, forKey: .user)
    try event.encode(self.channel, forKey: .channel)
  }
}

private let dialogflowDateFormatter = DateFormatter()
  |> iso8601
  |> \.dateFormat .~ "yyyy-MM-dd'T'HH:mm:ssxxxxx"

public let dialogflowJsonDecoder = JSONDecoder()
  |> \.dateDecodingStrategy .~ .formatted(dialogflowDateFormatter)

public let dialogflowJsonEncoder = JSONEncoder()
  |> \.dateEncodingStrategy .~ .formatted(dialogflowDateFormatter)
  |> sortedKeysOutputFormatting
