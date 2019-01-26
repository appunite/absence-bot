import Foundation

public struct InteractiveAction {
  public private(set) var name: String
  public private(set) var text: String?
  public private(set) var type: String
  public private(set) var value: Action
  
  public enum Action: String, Codable {
    case accept = "yes"
    case reject = "no"
    
    public func isApproved() -> Bool {
      switch self {
      case .accept: return true
      case .reject: return false
      }
    }
  }
  
  public init(name: String, text: String, value: Action) {
    self.name = name
    self.text = text
    self.value = value
    self.type = "button"
  }
}

extension InteractiveAction: Codable {}

extension InteractiveAction {
  public static func acceptAction() -> InteractiveAction {
    return InteractiveAction(name: "accept", text: "Accept 👍", value: .accept)
  }
  
  public static func rejectAction() -> InteractiveAction {
    return InteractiveAction(name: "reject", text: "Reject 👎", value: .reject)
  }
}
