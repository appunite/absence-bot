import Foundation

public struct InteractiveMessageFallback {
  public private(set) var text: String?
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
  public init(text: String?, attachments: [Slack.Message.Attachment]) {
    self.text = text
    self.attachments = attachments
    self.responseType = "ephemeral"
    self.replaceOriginal = true
  }
}

extension InteractiveMessageFallback: Codable {}

extension InteractiveMessageFallback {
  public static func rejectionFallback(absence: Absence) -> InteractiveMessageFallback {
    return .init(
      text: nil,
      attachments: [
        .approvalRequestAttachement(absence: absence, callback: nil, actions: nil),
        .rejectionAttachement(absence: absence)]
    )
  }

  public static func acceptanceFallback(absence: Absence) -> InteractiveMessageFallback {
    return .init(
      text: nil,
      attachments: [
        .approvalRequestAttachement(absence: absence, callback: nil, actions: nil),
        .acceptanceAttachement(absence: absence)]
    )
  }
}
