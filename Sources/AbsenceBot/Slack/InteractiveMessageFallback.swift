import Foundation

public struct InteractiveMessageFallback {
  public private(set) var responseType: String
  public private(set) var replaceOriginal: Bool
  public private(set) var text: String
  public private(set) var attachments: [Slack.Message.Attachment]
  
  enum CodingKeys: String, CodingKey {
    case responseType = "response_type"
    case replaceOriginal = "replace_original"
    case text = "text"
    case attachments
  }
}

extension InteractiveMessageFallback: Codable {}
