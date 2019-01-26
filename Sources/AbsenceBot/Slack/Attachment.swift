import Foundation

public struct Attachment {
  public private(set) var fallback: String?
  public private(set) var text: String
  public private(set) var callbackId: String?
  public private(set) var actions: [InteractiveAction]?

  enum CodingKeys: String, CodingKey {
    case fallback
    case text
    case callbackId = "callback_id"
    case actions
  }
}

extension Attachment: Codable {}
