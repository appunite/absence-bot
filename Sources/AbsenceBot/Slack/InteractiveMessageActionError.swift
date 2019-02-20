import Foundation

struct InteractiveMessageActionError {
  public private(set) var text: String
  public private(set) var replace: Bool
  public private(set) var type: String

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
