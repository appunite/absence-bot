import Foundation

public struct InteractiveMessageFallback {
  public private(set) var text: String
  public private(set) var attachments: [Slack.Message.Attachment]
  public private(set) var responseType: String
  public private(set) var replaceOriginal: Bool
  
  enum CodingKeys: String, CodingKey {
    case text = "text"
    case attachments
    case responseType = "response_type"
    case replaceOriginal = "replace_original"
  }
}

extension InteractiveMessageFallback {
  public init(text: String, attachment: Slack.Message.Attachment, responseType: String = "ephemeral", replaceOriginal: Bool = true) {
    self.text = text
    self.attachments = [attachment]
    self.responseType = responseType
    self.replaceOriginal = replaceOriginal
  }
}


extension InteractiveMessageFallback: Codable {}

extension Slack.Message.Attachment {
  public static func acceptanceAttachement(reviewer: String, requester: String, eventLink: String) -> Slack.Message.Attachment {
    return .init(text: "Thank you, <@\(reviewer)>, for making this decision! I've already created the <\(eventLink)|event> in absence calendar and I'll notify <@\(requester)> about this fact", fallback: nil, callbackId: nil, actions: nil)
  }
  
  public static func rejectionAttachement(reviewer: String, requester: String) -> Slack.Message.Attachment {
    return .init(
      text: "Thank you, <@\(reviewer)>, for making this decision! I'll notify <@\(requester)> about rejecting absence request", fallback: nil, callbackId: nil, actions: nil)
  }
  
  public static func pendingAttachement(reviewer: String) -> Slack.Message.Attachment {
    return .init(
      text: "Thank you, <@\(reviewer)>. Give me a second, I need to process this.", fallback: nil, callbackId: nil, actions: nil)
  }
}
