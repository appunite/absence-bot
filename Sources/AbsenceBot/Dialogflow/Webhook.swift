import Foundation

public struct Webhook: Equatable {
  public private(set) var session: URL
  public private(set) var user: Slack.User.Id?
  public private(set) var action: Action
  public private(set) var outputContexts: [Context]
  
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
    let event = try payload
      .nestedContainer(keyedBy: Webhook.SlackDataCodingKeys.self, forKey: .data)
    let user = try event
      .nestedContainer(keyedBy: Webhook.SlackEventCodingKeys.self, forKey: .event)
    self.user = try user.decodeIfPresent(Slack.User.Id.self, forKey: .user)
  }
}

public let dialogflowJsonDecoder: JSONDecoder = { () in
  let decoder = JSONDecoder()
  
  if #available(OSX 10.12, *) {
    decoder.dateDecodingStrategy = .iso8601
  } else {
    fatalError()
  }
  
  return decoder
}()

public let dialogflowJsonEncoder: JSONEncoder = { () in
  let encoder = JSONEncoder()
  
  if #available(OSX 10.12, *) {
    encoder.dateEncodingStrategy = .iso8601
  } else {
    fatalError()
  }
  
  return encoder
}()
