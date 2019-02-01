import Foundation

//public struct InteractiveAction {
//  public private(set) var name: String
//  public private(set) var text: String?
//  public private(set) var type: String
//  public private(set) var value: Action
//  
//  public enum Action: String, Codable {
//    case accept = "yes"
//    case reject = "no"
//    
//    public func isApproved() -> Bool {
//      switch self {
//      case .accept: return true
//      case .reject: return false
//      }
//    }
//  }
//
//  private static func accept() -> InteractiveAction {
//    return InteractiveAction(name: "accept", text: "Accept 👍", type: "button", value: .accept)
//  }
//
//  private static func reject() -> InteractiveAction {
//    return InteractiveAction(name: "reject", text: "Reject 👎", type: "button", value: .reject)
//  }
//}
//
//extension InteractiveAction: Codable {}
