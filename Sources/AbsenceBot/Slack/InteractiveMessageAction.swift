import Foundation

public struct InteractiveMessageAction {
  public private(set) var actions: [InteractiveAction]
  public private(set) var callbackId: UUID
  public private(set) var user: User
  public private(set) var channel: Channel
  public private(set) var responseURL: URL
  public private(set) var originalMessage: Message
  
  public struct Message {
    public private(set) var text: String
  }
  
  public struct User {
    public private(set) var id: String
    public private(set) var name: String
  }
  
  public struct Channel {
    public private(set) var id: String
    public private(set) var name: String
  }
  
  enum CodingKeys: String, CodingKey {
    case actions
    case callbackId = "callback_id"
    case user
    case channel
    case responseURL = "response_url"
    case originalMessage = "original_message"
  }
}

extension InteractiveMessageAction: Codable {}
extension InteractiveMessageAction.Message: Codable {}
extension InteractiveMessageAction.User: Codable {}
extension InteractiveMessageAction.Channel: Codable {}

//todo:

/*
 
 Error
 {
 "response_type": "ephemeral",
 "replace_original": false,
 "text": "Sorry, that didn't work. Please try again."
 }
 */
