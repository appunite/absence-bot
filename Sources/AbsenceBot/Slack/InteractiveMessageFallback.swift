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
  public init(text: String?, attachment: Slack.Message.Attachment, responseType: String = "ephemeral", replaceOriginal: Bool = true) {
    self.text = text
    self.attachments = [attachment]
    self.responseType = responseType
    self.replaceOriginal = replaceOriginal
  }
}

extension InteractiveMessageFallback: Codable {}

extension InteractiveMessageFallback {
  public static func rejectionFallback(absence: Absence) -> InteractiveMessageFallback {
    return .init(
      text: nil,
      attachment: .rejectionAttachement(absence: absence)
    )
  }

  public static func acceptanceFallback(absence: Absence) -> InteractiveMessageFallback {
    return .init(
      text: nil,
      attachment: .acceptanceAttachement(absence: absence)
    )
  }
}
