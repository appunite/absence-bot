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

extension Slack.Message.Attachment {
  public static func approvedAttachement(reviewer: String, requester: String, eventLink: String) -> Slack.Message.Attachment {
    return .init(text: "Thank you, <@\(reviewer)>, for making this decision! I've already created the <\(eventLink)|event> in absence calendar and I'll notify <@\(requester)> about this fact", fallback: nil, callbackId: nil, actions: nil)
  }
  
  public static func rejectedAttachement(reviewer: String, requester: String) -> Slack.Message.Attachment {
    return .init(
      text: "Thank you, <@\(reviewer)>, for making this decision! I'll notify <@\(requester)> about rejecting absence request", fallback: nil, callbackId: nil, actions: nil)
  }
  
  public static func pendingAttachement(reviewer: String) -> Slack.Message.Attachment {
    return .init(
      text: "Thank you, <@\(reviewer)>. Give me a second, I need to process this.", fallback: nil, callbackId: nil, actions: nil)
  }
}
