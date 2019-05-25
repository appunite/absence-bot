import Foundation

struct InteractiveMessageActionError {
  public var text: String
  public var replace: Bool
  public var type: String

  enum CodingKeys: String, CodingKey {
    case type = "response_type"
    case replace = "replace_original"
    case text
  }
}

extension InteractiveMessageActionError {
  init(text: String) {
    self.text = text
    self.replace = false
    self.type = "ephemeral"
  }
}

extension InteractiveMessageActionError: Codable {}
